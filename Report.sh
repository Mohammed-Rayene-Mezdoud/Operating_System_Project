#!/bin/bash

# 1. IDENTIFY THE ACTUAL USER (Handles cases where script is run with sudo)
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

# Find the Desktop path reliably
DESKTOP_PATH=$(sudo -u "$REAL_USER" xdg-user-dir DESKTOP 2>/dev/null)
if [ -z "$DESKTOP_PATH" ] || [ ! -d "$DESKTOP_PATH" ]; then
    DESKTOP_PATH="$REAL_HOME/Desktop"
fi

REPORT_DIR="$DESKTOP_PATH/system_report"

# 2. INSTALL TOOLS IF MISSING
if ! command -v enscript &> /dev/null || ! command -v ps2pdf &> /dev/null || ! command -v curl &> /dev/null; then
    echo "Updating and installing required tools..."
    sudo apt update && sudo apt install enscript ghostscript curl -y
fi

# 3. SETUP DIRECTORY
mkdir -p "$REPORT_DIR"

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
HOSTNAME=$(hostname)

# 4. GENERATE CONTENT
TEMP_FULL="/tmp/full_audit.txt"
TEMP_SHORT="/tmp/short_audit.txt"

# --- FULL REPORT GENERATION (UNTOUCHED) ---
{
    echo "=========================================================="
    echo "                 FULL SYSTEM AUDIT REPORT               "
    echo "=========================================================="
    echo "Generated On : $TIMESTAMP"
    echo "Target Host  : $HOSTNAME"
    echo "----------------------------------------------------------"


echo -e "\n[SECTION 1: HARDWARE - CPU & GPU]"

# --- CPU Data ---
CPU_MODEL=$(lscpu | grep 'Model name' | cut -d: -f2 | xargs)

# Usage Percentage: Calculated by subtracting the 'idle' % from 100
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8"%"}' | sed 's/,/./g')

# Load Average: Shows the process queue over 1, 5, and 15 minutes
CPU_LOAD_AVG=$(uptime | awk -F'load average:' '{ print $2 }' | sed 's/ //g')

# Temperature: Clean output without the 'Â' glitch
CPU_TEMP=$(awk '{printf "%.1f C\n", $1/1000}' /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo "N/A")

echo "CPU Model:      $CPU_MODEL"
echo "Architecture:   $(uname -m)"
echo "CPU Usage:      $CPU_USAGE"
echo "CPU Load Avg:   $CPU_LOAD_AVG"
echo "Temperature:    $CPU_TEMP"

# --- GPU Data ---
echo -e "\nGPU Information & Usage:"
if command -v nvidia-smi &> /dev/null; then
    # If NVIDIA drivers are installed and active
    nvidia-smi --query-gpu=name,driver_version,utilization.gpu,temperature.gpu --format=csv,noheader
else
    # Fallback for integrated or non-proprietary drivers
    lspci | grep -i 'vga\|3d\|display' | cut -d: -f3 | sed 's/\[//g; s/\]//g' | while read -r line; do
        echo "- $line"
    done
    echo -e "\nNote: Detailed GPU usage % usually requires proprietary drivers (NVIDIA/AMD)."
fi



    echo -e "\n[SECTION 2: RAM - DETAILED MEMORY]"
    free -h | awk '/^Mem:/ {print "Summary: Total: "$2" | Used: "$3" | Free: "$4" | Available: "$7}'
    echo -e "\nHardware RAM Slots (Physical):"
    sudo dmidecode -t memory | grep -E "Size:|Type:|Speed:|Manufacturer|Part Number" | grep -v "No Module Installed" || echo "Hardware RAM data restricted."

    echo -e "\n[SECTION 3: NETWORK - CONNECTIVITY]"
    PRIVATE_IP=$(hostname -I | awk '{print $1}')
    PUBLIC_IP=$(curl -s https://ifconfig.me || echo "Offline/Unknown")
    WIFI_SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2 || echo "Not connected to Wi-Fi")
    
    echo "Connected Wi-Fi: $WIFI_SSID"
    echo "Private IP:      $PRIVATE_IP"
    echo "Public IP:       $PUBLIC_IP"
    echo -e "\nInterface Status:"
    ip -brief addr

    echo -e "\n[SECTION 4: MOTHERBOARD & DISK]"
    sudo dmidecode -t baseboard | grep -E "Manufacturer|Product Name|Version" 2>/dev/null
    echo -e "\nDisk Usage & Filesystems:"
    df -Th --total | grep -v 'tmpfs'
    echo -e "\nUSB Devices:"
    lsusb | cut -d' ' -f7-

    echo -e "\n----------------------------------------------------------"
    echo -e "[SECTION 5: SOFTWARE & SECURITY]"
    echo "OS:              $(grep '^PRETTY_NAME' /etc/os-release | cut -d'=' -f2 | tr -d '\"')"
    echo "Kernel:          $(uname -r)"
    
    echo -e "\nLogged-in Users:"
    who
    echo -e "\nRunning Services (Active):"
    systemctl list-units --type=service --state=running --no-pager | head -n 15
    echo -e "\nListening Ports:"
    ss -tuln | grep LISTEN
    echo -e "\nPackage Count:"
    dpkg -l | wc -l | xargs echo "Total Installed:"


    # Fetch battery path
    BAT_PATH=$(upower -e | grep 'BAT' | head -n 1)

    # Check if battery exists to avoid errors
    if [ -n "$BAT_PATH" ]; then
    BAT_INFO=$(upower -i "$BAT_PATH")
    
    echo -e "\n[SECTION 6: BATTERY STATUS ]"
    echo "Current Level:  $(echo "$BAT_INFO" | grep "percentage" | awk '{print $2}')"
    echo "Battery Health: $(echo "$BAT_INFO" | grep "capacity" | awk '{print $2}')"
    echo "Power State:    $(echo "$BAT_INFO" | grep "state" | awk '{print $2}')"
    else
    echo -e "\n[SECTION 6: BATTERY STATUS ]"
    echo "Status:         No Battery Detected"
    fi





} > "$TEMP_FULL"

# --- SHORT REPORT GENERATION (MODIFIED WITH NEW REQUIREMENTS) ---
{
    echo "----------------------------------------------------------"
    echo "          EXECUTIVE HARDWARE SUMMARY: $HOSTNAME"
    echo "                Report Date: $TIMESTAMP"
    echo "----------------------------------------------------------"
    
    echo -e "\n[ SYSTEM IDENTIFICATION ]"
    echo "Hostname:      $HOSTNAME"
    echo "Uptime:        $(uptime -p)"
    echo "Load Average:  $(cat /proc/loadavg | awk '{print $1, $2, $3}')"
    
    echo -e "\n[ PROCESSOR & GRAPHICS ]"
    echo "CPU Model:     $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
    echo "CPU Load:      $(top -bn1 | grep 'Cpu(s)' | awk '{print 100 - $8"%"}')"
    echo "Detected GPUs:"
    lspci | grep -Ei "vga|3d|display" | cut -d: -f3 | sed 's/^/  - /'

    echo -e "\n[ MEMORY & STORAGE ]"
    echo "RAM Available: $(free -h | awk '/^Mem:/ {print $7}')"
    echo "Disk Status:   $(df -h / | awk 'NR==2 {print $3 " used of " $2 " (" $5 ")" }')"
    
    echo -e "\n[ LOGGED USERS ]"
    who | awk '{print "  - User: "$1" (Term: "$2")"}' | head -n 5

    echo -e "\n[ TOP 5 PROCESSES (BY CPU) ]"
    echo "  PID    %CPU  COMMAND"
    ps -eo pid,pcpu,comm --sort=-pcpu | head -n 6 | tail -n 5 | sed 's/^/  /'

    echo -e "\n[ NETWORK SUMMARY ]"
    echo "Active Wi-Fi:  $(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2 || echo 'N/A')"
    echo "IPv4 Address:  $(hostname -I | awk '{print $1}')"
    
    echo -e "\n----------------------------------------------------------"
    echo "            Generated by System Audit Utility"
    echo "----------------------------------------------------------"
} > "$TEMP_SHORT"

# 5. PDF CONVERSION
enscript -B -f Courier8 -p - "$TEMP_FULL" 2>/dev/null | ps2pdf - "$REPORT_DIR/full_report.pdf"
enscript -B -f Courier10 -p - "$TEMP_SHORT" 2>/dev/null | ps2pdf - "$REPORT_DIR/short_report.pdf"

# 6. FIX PERMISSIONS & CLEANUP
chown -R "$REAL_USER":"$REAL_USER" "$REPORT_DIR"
rm "$TEMP_FULL" "$TEMP_SHORT"

echo "-----------------------------------------------------"
echo "Success! Reports created on your Desktop."
echo "Location: $REPORT_DIR"
echo "-----------------------------------------------------"

# 7. FORCE OPEN THE FOLDER
sudo -u "$REAL_USER" xdg-open "$REPORT_DIR" 2>/dev/null