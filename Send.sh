#!/bin/bash

# --- 1. ERROR CHECKING FUNCTIONS ---

check_connection() {
    echo -e "\e[34m[*] Checking internet connection...\e[0m"
    if ! ping -c 1 8.8.8.8 &>/dev/null; then
        echo -e "\e[31m[!] Error: No internet connection. Please connect to Wi-Fi.\e[0m"
        exit 1
    fi
}

validate_email() {
    local email=$1
    if [[ ! "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$ ]]; then
        echo -e "\e[31m[!] Error: '$email' is not a valid email format.\e[0m"
        return 1
    fi
    return 0
}

# --- 2. PATHS & DIRECTORIES ---
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
DESKTOP_PATH=$(sudo -u "$REAL_USER" xdg-user-dir DESKTOP 2>/dev/null || echo "$REAL_HOME/Desktop")
REPORT_DIR="$DESKTOP_PATH/system_report"
SHORT_PDF="$REPORT_DIR/short_report.pdf"
FULL_PDF="$REPORT_DIR/full_report.pdf"

# --- 3. INTERNAL GENERATION (If reports are missing) ---
if [[ ! -f "$SHORT_PDF" || ! -f "$FULL_PDF" ]]; then
    echo -e "\e[33m[!] Reports not found. Generating professional audit files...\e[0m"
    mkdir -p "$REPORT_DIR"
    
    # Ensure dependencies are present
    if ! command -v enscript &>/dev/null || ! command -v ps2pdf &>/dev/null || ! command -v curl &>/dev/null; then
        sudo apt update && sudo apt install enscript ghostscript curl -y
    fi

    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    HOSTNAME=$(hostname)
    TEMP_FULL="/tmp/full_audit.txt"
    TEMP_SHORT="/tmp/short_audit.txt"

    # --- FULL REPORT LOGIC ---
{
    echo "=========================================================="
    echo "                 FULL SYSTEM AUDIT REPORT               "
    echo "=========================================================="
    echo "Generated On : $TIMESTAMP"
    echo "Target Host  : $HOSTNAME"
    echo "----------------------------------------------------------"

    echo -e "\n[SECTION 1: HARDWARE - CPU & GPU]"
    lscpu | grep 'Model name'
    echo "Architecture: $(uname -m)"
    echo "CPU Usage: $(top -bn1 | grep 'Cpu(s)' | awk '{print 100 - $8"%"}')"
    echo "CPU Load Avg: $(cat /proc/loadavg | awk '{print $1, $2, $3}')"
    echo "Temperature: $(awk '{printf "%.1f C\n", $1/1000}' /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo "N/A")"
    echo "GPU Info: $(lspci | grep -i 'vga\|3d\|display')"
    echo "GPU Usage: $(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null || echo 'N/A')%"

    echo -e "\n[SECTION 2: RAM - DETAILED MEMORY]"
    free -h
    sudo dmidecode -t memory | grep -E "Size:|Type:|Speed:|Manufacturer|Part Number" | grep -v "No Module Installed"

    echo -e "\n[SECTION 3: NETWORK - CONNECTIVITY]"
    echo "Connected Wi-Fi: $(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)"
    echo "Private IP: $(hostname -I | awk '{print $1}')"
    echo "Public IP: $(curl -s https://ifconfig.me)"
    echo "MAC Addresses: $(ip link show | grep link/ether | awk '{print $2}')"
    echo "Active IPs: $(hostname -I)"
    

    echo -e "\n[SECTION 4: MOTHERBOARD & DISK]"
    sudo dmidecode -t baseboard | grep -E "Manufacturer|Product Name|Version"
    df -Th --total | grep -v 'tmpfs'
    echo -e "\nUSB Devices:"
    lsusb | cut -d' ' -f7-
    

    echo -e "\n[SECTION 5: SOFTWARE & SECURITY]"
    echo "OS: $(grep '^PRETTY_NAME' /etc/os-release | cut -d'=' -f2)"
    echo "Kernel: $(uname -r)"
    echo -e "\nRunning Services (Top 10):"
    systemctl list-units --type=service --state=running --no-pager | head -n 12
    echo -e "\nListening Ports:"
    ss -tuln | grep LISTEN
    echo -e "\nLogged-in Users:"
    who
    echo -e "\nPackage Count: $(dpkg --get-selections | wc -l)"
    

    echo -e "\n[SECTION 6: BATTERY STATUS]"
    upower -i $(upower -e | grep 'BAT') | grep -E "state|percentage|capacity"
    
    } > "$TEMP_FULL"
    



    # --- PROFESSIONAL SHORT REPORT LOGIC (Matched to provided PDF) ---
    {
        echo "----------------------------------------------------------"
        echo "          EXECUTIVE HARDWARE SUMMARY: $HOSTNAME"
        echo "                Report Date: $TIMESTAMP"
        echo "----------------------------------------------------------"
        
        echo -e "\n[ SYSTEM IDENTIFICATION ]"
        echo "Hostname:      $HOSTNAME"
        echo "Uptime:        $(uptime -p)"
        echo "Load Average:  $(cat /proc/loadavg | awk '{print $1, $2, $3}')"

        echo -e "\n[ MOTHERBOARD & DISK DETAILS ]"
        sudo dmidecode -t baseboard | grep -E "Manufacturer|Product Name|Version"
        
        
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

    # Convert to PDF
    enscript -B -f Courier8 -p - "$TEMP_FULL" 2>/dev/null | ps2pdf - "$FULL_PDF"
    enscript -B -f Courier10 -p - "$TEMP_SHORT" 2>/dev/null | ps2pdf - "$SHORT_PDF"
    
    # Set permissions and cleanup
    chown -R "$REAL_USER":"$REAL_USER" "$REPORT_DIR"
    rm "$TEMP_FULL" "$TEMP_SHORT"
    echo -e "\e[32m[+] Reports generated successfully.\e[0m"
fi

# --- 4. EMAIL TRANSMISSION ---
check_connection

echo -e "\n--- Email Settings ---"
while true; do
    read -p "Enter YOUR Gmail Address: " SENDER_GMAIL
    validate_email "$SENDER_GMAIL" && break
done

read -s -p "Enter YOUR Gmail App Password: " SENDER_PASS
echo -e "\n"

while true; do
    read -p "Enter RECIPIENT Email Address: " RECIPIENT_EMAIL
    validate_email "$RECIPIENT_EMAIL" && break
done

# Temporary MSMTP Configuration
MSMTP_CONF="/tmp/.msmtp_tmp.conf"
cat <<EOF > "$MSMTP_CONF"
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
account        gmail
host           smtp.gmail.com
port           587
from           $SENDER_GMAIL
user           $SENDER_GMAIL
password       $SENDER_PASS
account default : gmail
EOF
chmod 600 "$MSMTP_CONF"

echo -e "\n\e[34m[*] Sending reports to $RECIPIENT_EMAIL...\e[0m"
BOUNDARY="BOUND_$(date +%s)"

(
  echo "To: $RECIPIENT_EMAIL"
  echo "From: $SENDER_GMAIL"
  echo "Subject: System Audit Results: $HOSTNAME"
  echo "MIME-Version: 1.0"
  echo "Content-Type: multipart/mixed; boundary=\"$BOUNDARY\""
  echo ""
  echo "--$BOUNDARY"
  echo "Content-Type: text/plain; charset=utf-8"
  echo ""
  echo "Attached are the Short and Full System Audit reports for $HOSTNAME."
  echo "Generated at: $(date)"
  echo ""
  
  echo "--$BOUNDARY"
  echo "Content-Type: application/pdf; name=\"short_report.pdf\""
  echo "Content-Transfer-Encoding: base64"
  echo "Content-Disposition: attachment; filename=\"short_report.pdf\""
  echo ""
  base64 "$SHORT_PDF"
  
  echo "--$BOUNDARY"
  echo "Content-Type: application/pdf; name=\"full_report.pdf\""
  echo "Content-Transfer-Encoding: base64"
  echo "Content-Disposition: attachment; filename=\"full_report.pdf\""
  echo ""
  base64 "$FULL_PDF"
  
  echo "--$BOUNDARY--"
) | msmtp -C "$MSMTP_CONF" "$RECIPIENT_EMAIL"

rm "$MSMTP_CONF"

if [ $? -eq 0 ]; then
    echo -e "\n\e[32mSuccess: Reports sent successfully!\e[0m"
else
    echo -e "\n\e[31mError: Transmission failed. Ensure you are using a 16-character App Password.\e[0m"
fi