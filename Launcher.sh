#!/bin/bash

# ============================================================
#   SYSTEM AUDIT TOOLKIT — Main Menu
# ============================================================

# Colors
W='\033[1;37m'; GR='\033[0;90m'; R='\033[0;31m'
G='\033[0;32m'; B='\033[0;34m'; C='\033[0;36m'
Y='\033[1;33m'; BD='\033[1m'; NC='\033[0m'
O='\033[0;33m'; OB='\033[1;33m'   # Orange / Bold Orange

# ============================================================
#   ROOT CHECK
# ============================================================
if [[ $EUID -ne 0 ]]; then
    echo -e "${R}${BD}ERROR:${NC} Run as root (sudo)."
    exit 1
fi

REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
DESKTOP_PATH=$(sudo -u "$REAL_USER" xdg-user-dir DESKTOP 2>/dev/null || echo "$REAL_HOME/Desktop")
REPORT_DIR="$DESKTOP_PATH/system_report"
LOG_DIR="/var/log/sysaudit"
mkdir -p "$LOG_DIR"

# ============================================================
#   MODULE 1 — HARDWARE AUDIT
# ============================================================
run_hardware() {
    clear
    echo -e "${OB}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${OB}║  HARDWARE AUDIT${NC}  ${GR}$(date '+%Y-%m-%d %H:%M:%S')${OB}                                 ║${NC}"
    echo -e "${OB}╚══════════════════════════════════════════════════════════════════════╝${NC}"

    echo -e "\n${O}${BD}▶ CPU${NC}\n${OB}──────────────────────────────────────────────────────────────────────${NC}"
    lscpu | grep -E 'Model name|Socket\(s\)|Core\(s\) per socket|Thread\(s\) per core|Architecture' | while IFS= read -r line; do
        key=$(echo "$line" | cut -d: -f1)
        val=$(echo "$line" | cut -d: -f2-)
        echo -e "  ${key}:${W}${val}${NC}"
    done

    echo -e "\n${O}${BD}▶ GPU${NC}\n${OB}──────────────────────────────────────────────────────────────────────${NC}"
    gpu=$(lspci | grep -iE 'vga|3d|display')
    [ -z "$gpu" ] && echo -e "  ${R}No discrete GPU detected.${NC}" || echo -e "  ${W}$gpu${NC}"

    echo -e "\n${O}${BD}▶ RAM${NC}\n${OB}──────────────────────────────────────────────────────────────────────${NC}"
    free -h | awk '/^Mem:/ {print "  \033[1mTotal/Available:\033[0m " $2 " / " $7}'
    dmidecode -t memory | grep -E "Size|Type|Speed|Manufacturer" | grep -v "No Module Installed" | sed 's/^/  /'

    echo -e "\n${O}${BD}▶ DISK${NC}\n${OB}──────────────────────────────────────────────────────────────────────${NC}"
    LANG=C lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINT | sed 's/^/  /'

    echo -e "\n${O}${BD}▶ NETWORK${NC}\n${OB}──────────────────────────────────────────────────────────────────────${NC}"
    nmcli device status 2>/dev/null | sed 's/^/  /' || ip -brief addr show | sed 's/^/  /'
    echo -e "\n  ${BD}MAC Addresses:${NC}"
    ip link show | grep link/ether | awk '{print "  - " $2}'
    echo -e "  ${BD}Active IPs:${NC} ${W}$(hostname -I)${NC}"

    echo -e "\n${O}${BD}▶ MOTHERBOARD${NC}\n${OB}──────────────────────────────────────────────────────────────────────${NC}"
    dmidecode -t baseboard | grep -E "Manufacturer|Product Name|Version|Serial Number" | sed 's/^/  /'

    echo -e "\n${O}${BD}▶ USB DEVICES${NC}\n${OB}──────────────────────────────────────────────────────────────────────${NC}"
    lsusb | cut -d ' ' -f 7- | while read -r line; do echo -e "  ${GR}•${NC} ${W}${line}${NC}"; done

    echo -e "\n${OB}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${OB}║  DONE${NC}  ${GR}$(date '+%Y-%m-%d %H:%M:%S')${OB}                                           ║${NC}"
    echo -e "${OB}╚══════════════════════════════════════════════════════════════════════╝${NC}"
}

# ============================================================
#   MODULE 2 — OS & SOFTWARE AUDIT
# ============================================================
run_os_software() {
    clear
    STATUS=""
    pass() { STATUS="${STATUS}  ${G}✔${NC}  $(printf '%-28s' "$1") [${G}OK${NC}]\n"; }
    fail() { STATUS="${STATUS}  ${R}✘${NC}  $(printf '%-28s' "$1") [${R}FAIL: $2${NC}]\n"; }

    echo -e "${OB}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${OB}║  OS & SOFTWARE AUDIT${NC}  ${GR}$(date '+%Y-%m-%d %H:%M:%S')${OB}                            ║${NC}"
    echo -e "${OB}╚══════════════════════════════════════════════════════════════════════╝${NC}"

    echo -e "\n${O}${BD}▶ OS INFO${NC}\n${OB}──────────────────────────────────────────────────────────────────────${NC}"
    OS_NAME=$(grep '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')
    echo -e "  ${BD}OS:${NC}           ${W}${OS_NAME:-$(uname -s)}${NC}"
    echo -e "  ${BD}Kernel:${NC}       ${W}$(uname -r)${NC}"
    echo -e "  ${BD}Architecture:${NC} ${W}$(uname -m)${NC}"
    echo -e "  ${BD}Hostname:${NC}     ${W}$(hostname)${NC}"

    echo -e "\n${O}${BD}▶ UPTIME & LOAD${NC}\n${OB}──────────────────────────────────────────────────────────────────────${NC}"
    uptime_p=$(uptime -p 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo -e "  ${BD}Uptime:${NC} ${W}$uptime_p${NC}  ${BD}Load:${NC} ${W}$(awk '{print $1,$2,$3}' /proc/loadavg)${NC}"
        pass "Uptime & Load"
    else
        fail "Uptime & Load" "uptime failed"
    fi

    echo -e "\n${O}${BD}▶ LOGGED-IN USERS${NC}\n${OB}──────────────────────────────────────────────────────────────────────${NC}"
    who | while read -r line; do echo -e "  ${GR}•${NC} ${W}$line${NC}"; done
    pass "Logged-in Users"

    echo -e "\n${O}${BD}▶ PACKAGES${NC}\n${OB}──────────────────────────────────────────────────────────────────────${NC}"
    if command -v dpkg &>/dev/null; then
        echo -e "  ${BD}Manager:${NC} ${W}dpkg/apt${NC}  ${BD}Total:${NC} ${W}$(dpkg -l | grep -c "^ii") packages${NC}"
        pass "Packages"
    elif command -v rpm &>/dev/null; then
        echo -e "  ${BD}Manager:${NC} ${W}rpm/yum${NC}  ${BD}Total:${NC} ${W}$(rpm -qa | wc -l) packages${NC}"
        pass "Packages"
    else
        fail "Packages" "no package manager"
    fi

    echo -e "\n${O}${BD}▶ ACTIVE SERVICES${NC}\n${OB}──────────────────────────────────────────────────────────────────────${NC}"
    if command -v systemctl &>/dev/null; then
        total=$(systemctl list-units --type=service --state=running --no-legend | wc -l)
        systemctl list-units --type=service --state=running --no-legend | head -5 | awk -v b="${BD}${W}" -v n="${NC}" '{print "  • " b $1 n}'
        echo -e "  ${GR}...and $total total active services.${NC}"
        pass "Active Services"
    else
        fail "Active Services" "systemd not found"
    fi

    echo -e "\n${O}${BD}▶ TOP PROCESSES (by RAM)${NC}\n${OB}──────────────────────────────────────────────────────────────────────${NC}"
    ps -eo pid,%mem,comm --sort=-%mem | head -6 | tail -5 | while read -r line; do echo -e "  ${W}$line${NC}"; done
    pass "Top Processes"

    echo -e "\n${O}${BD}▶ OPEN PORTS${NC}\n${OB}──────────────────────────────────────────────────────────────────────${NC}"
    if command -v ss &>/dev/null; then
        ss -tulpn | grep LISTEN | head -5 | awk -v b="${BD}${W}" -v n="${NC}" '{print "  • " b $5 " ("$1")" n}'
        pass "Open Ports"
    else
        fail "Open Ports" "ss missing"
    fi

    echo -e "\n${OB}──────────────────────────────────────────────────────────────────────${NC}"
    echo -e "  ${OB}${BD}SUMMARY${NC}"
    echo -e "${OB}──────────────────────────────────────────────────────────────────────${NC}"
    echo -e "$STATUS"
    echo -e "${OB}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${OB}║  DONE${NC}  ${GR}$(date '+%Y-%m-%d %H:%M:%S')${OB}                                           ║${NC}"
    echo -e "${OB}╚══════════════════════════════════════════════════════════════════════╝${NC}"
}

# ============================================================
#   MODULE 3 — GENERATE PDF REPORTS
# ============================================================
run_report() {
    echo -e "${O}[*] Checking dependencies (enscript, ghostscript, curl)...${NC}"
    apt-get install -y enscript ghostscript curl &>/dev/null

    mkdir -p "$REPORT_DIR"
    TS=$(date "+%Y-%m-%d %H:%M:%S")
    HOST=$(hostname)
    FULL_TXT="/tmp/full_audit.txt"
    SHORT_TXT="/tmp/short_audit.txt"

    echo -e "${O}[*] Collecting full report data...${NC}"
    {
        echo "=========================================================="
        echo "              FULL SYSTEM AUDIT REPORT"
        echo "=========================================================="
        echo "Generated On : $TS"
        echo "Target Host  : $HOST"
        echo "----------------------------------------------------------"
        echo ""

        echo "[SECTION 1: HARDWARE - CPU & GPU]"
        echo "CPU Model: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
        echo "Architecture: $(uname -m)"
        echo "CPU Usage: $(top -bn2 | grep 'Cpu(s)' | tail -1 | awk '{printf "%.1f%%\n", 100-$8}')"
        echo "CPU Load Avg: $(awk '{print $1","$2","$3}' /proc/loadavg)"
        echo "Temperature: $(awk '{printf "%.1f C\n",$1/1000}' /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo N/A)"
        echo "GPU Information & Usage:"
        lspci | grep -iE 'vga|3d|display' | cut -d: -f3 | sed 's/^ //' | while read -r g; do echo "- $g"; done
        echo "Note: Detailed GPU usage % usually requires proprietary drivers (NVIDIA/AMD)."

        echo ""
        echo "[SECTION 2: RAM - DETAILED MEMORY]"
        echo "Summary: $(free -h | awk '/^Mem:/ {printf "Total: %s | Used: %s | Free: %s | Available: %s\n",$2,$3,$4,$7}')"
        echo "Hardware RAM Slots (Physical):"
        dmidecode -t memory 2>/dev/null | grep -E "Error Correction Type:|Size:|Type:|Speed:|Manufacturer:|Part Number:|Configured Memory Speed:" | grep -v "No Module Installed" | sed 's/^\s*/  /'

        echo ""
        echo "[SECTION 3: NETWORK - CONNECTIVITY]"
        echo "Connected Wi-Fi: $(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2 || echo N/A)"
        echo "Private IP: $(hostname -I | awk '{print $1}')"
        echo "Public IP: $(curl -s https://ifconfig.me 2>/dev/null || echo Offline)"
        echo "Interface Status:"
        ip -brief addr

        echo ""
        echo "[SECTION 4: MOTHERBOARD & DISK]"
        dmidecode -t baseboard 2>/dev/null | grep -E "Manufacturer:|Product Name:|Version:" | sed 's/^\s*//'
        echo "Disk Usage & Filesystems:"
        df -Th --total | grep -v tmpfs
        echo "USB Devices:"
        lsusb | cut -d' ' -f7-

        echo ""
        echo "----------------------------------------------------------"
        echo "[SECTION 5: SOFTWARE & SECURITY]"
        echo "OS: $(grep '^PRETTY_NAME' /etc/os-release | cut -d= -f2 | tr -d '"')"
        echo "Kernel: $(uname -r)"
        echo "Logged-in Users:"
        who | awk '{printf "%s %s %s %s\n",$1,$2,$3,$4}'
        echo "Running Services (Active):"
        systemctl list-units --type=service --state=running --no-pager | head -20
        echo "Listening Ports:"
        ss -tulpn | grep LISTEN
        echo "Package Count:"
        echo "Total Installed: $(dpkg -l 2>/dev/null | grep -c '^ii')"

        echo ""
        echo "[SECTION 6: BATTERY STATUS ]"
        BAT=$(upower -e 2>/dev/null | grep 'BAT' | head -1)
        if [ -n "$BAT" ]; then
            BPCT=$(upower -i "$BAT" | grep percentage | awk '{print $2}')
            BSTATE=$(upower -i "$BAT" | grep state | awk '{print $2}')
            BCAP=$(upower -i "$BAT" | grep capacity | awk '{print $2}')
            echo "Current Level: $BPCT"
            echo "Battery Health: Normal"
            echo "$BCAP"
            echo "Power State: $BSTATE"
        else
            echo "No battery detected."
        fi
    } > "$FULL_TXT"

    echo -e "${O}[*] Collecting short report data...${NC}"
    {
        echo "----------------------------------------------------------"
        echo "        EXECUTIVE HARDWARE SUMMARY: $HOST"
        echo "        Report Date: $TS"
        echo "----------------------------------------------------------"

        echo ""
        echo "[ SYSTEM IDENTIFICATION ]"
        echo "Hostname: $HOST"
        echo "Uptime: $(uptime -p)"
        echo "Load Average: $(awk '{print $1,$2,$3}' /proc/loadavg)"

        echo ""
        echo "[ PROCESSOR & GRAPHICS ]"
        echo "CPU Model: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
        echo "CPU Load: $(top -bn2 | grep 'Cpu(s)' | tail -1 | awk '{printf "%.1f%%\n", 100-$8}')"
        echo "Detected GPUs:"
        lspci | grep -Ei "vga|3d|display" | cut -d: -f3 | sed 's/^ / - /'

        echo ""
        echo "[ MEMORY & STORAGE ]"
        echo "RAM Available: $(free -h | awk '/^Mem:/ {print $7}')"
        echo "Disk Status: $(df -h / | awk 'NR==2 {print $3" used of "$2" ("$5")"}')"

        echo ""
        echo "[ LOGGED USERS ]"
        who | awk '{printf " - User: %s (Term: %s)\n",$1,$2}'

        echo ""
        echo "[ TOP 5 PROCESSES (BY CPU) ]"
        ps -eo pid,pcpu,comm --sort=-pcpu | head -6 | tail -5 | awk '{printf " %s %s %s\n",$1,$2,$3}'

        echo ""
        echo "[ NETWORK SUMMARY ]"
        echo "Active Wi-Fi: $(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2 || echo N/A)"
        echo "IPv4 Address: $(hostname -I | awk '{print $1}')"

        echo ""
        echo "----------------------------------------------------------"
        echo "           Generated by System Audit Utility"
        echo "----------------------------------------------------------"
    } > "$SHORT_TXT"

    echo -e "${O}[*] Converting to PDF...${NC}"
    enscript -B -f Courier8  -p - "$FULL_TXT"  2>/dev/null | ps2pdf - "$REPORT_DIR/full_report.pdf"
    enscript -B -f Courier10 -p - "$SHORT_TXT" 2>/dev/null | ps2pdf - "$REPORT_DIR/short_report.pdf"

    rm -f "$FULL_TXT" "$SHORT_TXT"
    chown -R "$REAL_USER":"$REAL_USER" "$REPORT_DIR"

    echo -e "${G}[+] Reports saved to: $REPORT_DIR${NC}"
    sudo -u "$REAL_USER" xdg-open "$REPORT_DIR" 2>/dev/null
}

# ============================================================
#   MODULE 4 — SEND REPORTS BY EMAIL
# ============================================================
run_send() {
    SHORT_PDF="$REPORT_DIR/short_report.pdf"
    FULL_PDF="$REPORT_DIR/full_report.pdf"

    if [[ ! -f "$SHORT_PDF" || ! -f "$FULL_PDF" ]]; then
        echo -e "${O}[!] Reports not found. Generating first...${NC}"
        run_report
    fi

    echo -e "${O}[*] Checking internet...${NC}"
    if ! ping -c 1 8.8.8.8 &>/dev/null; then
        echo -e "${R}[!] No internet connection.${NC}"; return
    fi

    command -v msmtp &>/dev/null || apt-get install -y msmtp &>/dev/null

    validate_email() { [[ "$1" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$ ]]; }

    while true; do read -p "Your Gmail: " SENDER; validate_email "$SENDER" && break; echo -e "${R}Invalid email.${NC}"; done
    read -s -p "App Password (16 chars): " PASS; echo
    while true; do read -p "Recipient Email: " RECIP; validate_email "$RECIP" && break; echo -e "${R}Invalid email.${NC}"; done

    CONF="/tmp/.msmtp_tmp.conf"
    cat > "$CONF" <<EOF
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
account        gmail
host           smtp.gmail.com
port           587
from           $SENDER
user           $SENDER
password       $PASS
account default : gmail
EOF
    chmod 600 "$CONF"

    echo -e "${O}[*] Sending to $RECIP...${NC}"
    BOUNDARY="BOUND_$(date +%s)"
    (
        echo "To: $RECIP"
        echo "From: $SENDER"
        echo "Subject: System Audit — $(hostname)"
        echo "MIME-Version: 1.0"
        echo "Content-Type: multipart/mixed; boundary=\"$BOUNDARY\""
        echo ""
        echo "--$BOUNDARY"
        echo "Content-Type: text/plain; charset=utf-8"
        echo ""
        echo "Attached: Short and Full System Audit reports for $(hostname)."
        echo "Generated: $(date)"
        echo ""
        for pdf in "$SHORT_PDF" "$FULL_PDF"; do
            name=$(basename "$pdf")
            echo "--$BOUNDARY"
            echo "Content-Type: application/pdf; name=\"$name\""
            echo "Content-Transfer-Encoding: base64"
            echo "Content-Disposition: attachment; filename=\"$name\""
            echo ""
            base64 "$pdf"
        done
        echo "--$BOUNDARY--"
    ) | msmtp -C "$CONF" "$RECIP"

    [ $? -eq 0 ] && echo -e "${G}[+] Sent successfully!${NC}" || echo -e "${R}[!] Failed. Check your App Password.${NC}"
    rm -f "$CONF"
}

# ============================================================
#   MODULE 5 — AUTOMATED REPORT + EMAIL (cron-friendly)
# ============================================================
run_automation() {
    LOG_FILE="$LOG_DIR/automation_$(date +%Y%m%d).log"
    echo -e "${O}[*] Starting automated run...${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Automation started" >> "$LOG_FILE"

    # Check internet
    if ! ping -c 1 8.8.8.8 &>/dev/null; then
        echo -e "${R}[!] No internet. Aborting.${NC}"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] FAILED — No internet" >> "$LOG_FILE"
        return
    fi

    # Generate reports
    run_report
    if [[ ! -f "$REPORT_DIR/short_report.pdf" || ! -f "$REPORT_DIR/full_report.pdf" ]]; then
        echo -e "${R}[!] Report generation failed. Aborting.${NC}"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] FAILED — Report generation error" >> "$LOG_FILE"
        return
    fi

    # Email credentials — hardcoded for cron automation
    SENDER_GMAIL="hassanhalis15@gmail.com"
    SENDER_PASS="endz xdvs wcxb tcll"
    RECIPIENT="hashouay159@gmail.com"

    command -v msmtp &>/dev/null || apt-get install -y msmtp &>/dev/null

    CONF="/tmp/.msmtp_auto.conf"
    cat > "$CONF" <<EOF
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
    chmod 600 "$CONF"

    BOUNDARY="BOUND_$(date +%s)"
    (
        echo "To: $RECIPIENT"
        echo "From: $SENDER_GMAIL"
        echo "Subject: Auto Audit — $(hostname)"
        echo "MIME-Version: 1.0"
        echo "Content-Type: multipart/mixed; boundary=\"$BOUNDARY\""
        echo ""
        echo "--$BOUNDARY"
        echo "Content-Type: text/plain; charset=utf-8"
        echo ""
        echo "Automated audit for $(hostname) — $(date)"
        echo ""
        for pdf in "$REPORT_DIR/short_report.pdf" "$REPORT_DIR/full_report.pdf"; do
            name=$(basename "$pdf")
            echo "--$BOUNDARY"
            echo "Content-Type: application/pdf; name=\"$name\""
            echo "Content-Transfer-Encoding: base64"
            echo "Content-Disposition: attachment; filename=\"$name\""
            echo ""
            base64 "$pdf"
        done
        echo "--$BOUNDARY--"
    ) | msmtp -C "$CONF" "$RECIPIENT"

    if [ $? -eq 0 ]; then
        echo -e "${G}[+] Auto-send complete!${NC}"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS — Email sent to $RECIPIENT" >> "$LOG_FILE"
    else
        echo -e "${R}[!] Send failed.${NC}"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] FAILED — Email send error" >> "$LOG_FILE"
    fi
    rm -f "$CONF"
}

# ============================================================
#   MODULE 6 — REMOTE MONITORING (SSH)
# ============================================================
run_monitoring() {
    REMOTE_DIR="$REAL_HOME/reports/remote"
    mkdir -p "$REMOTE_DIR"

    command -v sshpass &>/dev/null || apt-get install -y sshpass &>/dev/null

    echo ""
    echo -e "${OB}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${OB}║              REMOTE MONITORING SETUP                                 ║${NC}"
    echo -e "${OB}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    read -p "  How many machines to monitor? " count

    MACHINES=(); USERS=(); PASSES=()
    for (( i=1; i<=count; i++ )); do
        echo -e "\n${O}--- Machine $i ---${NC}"
        read -p "  IP Address : " ip
        read -p "  Username   : " user
        read -s -p "  Password   : " pass; echo
        MACHINES+=("$ip"); USERS+=("$user"); PASSES+=("$pass")
    done

    for (( i=0; i<${#MACHINES[@]}; i++ )); do
        ip="${MACHINES[$i]}"; user="${USERS[$i]}"; pass="${PASSES[$i]}"
        echo -e "\n${O}[*] Connecting to $user@$ip...${NC}"

        sshpass -p "$pass" ssh -p 22 -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$user@$ip" "echo ok" &>/dev/null
        if [ $? -ne 0 ]; then echo -e "${R}[!] Cannot connect to $ip — skipping.${NC}"; continue; fi
        echo -e "${G}[+] Connected.${NC}"

        TMP_TXT="/tmp/remote_${ip}_$(date +%Y%m%d_%H%M%S).txt"
        OUT_PDF="$REMOTE_DIR/${ip}_$(date +%Y%m%d_%H%M%S).pdf"
        sshpass -p "$pass" ssh -p 22 -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$user@$ip" bash << 'REMOTE' > "$TMP_TXT"
echo "================================================================"
echo "  REMOTE AUDIT | Host: $(hostname) | IP: $(hostname -I | awk '{print $1}') | $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "================================================================"
echo -e "\n[OS]";       uname -a; cat /etc/os-release 2>/dev/null | grep PRETTY_NAME; uptime
echo -e "\n[CPU]";      lscpu 2>/dev/null | grep -E "Model|MHz|Cores"; top -bn1 | grep "Cpu(s)"
echo -e "\n[RAM]";      free -h; cat /proc/meminfo | grep -E "MemTotal|MemAvailable|SwapTotal"
echo -e "\n[DISK]";     df -h | grep -v tmpfs; LANG=C lsblk -o NAME,SIZE,TYPE,MOUNTPOINT 2>/dev/null
echo -e "\n[NETWORK]";  ip -brief addr; ss -tuln | head -15
echo -e "\n[SERVICES]"; systemctl list-units --type=service --state=running 2>/dev/null | head -20
echo -e "\n[TOP PROCS]"; ps aux --sort=-%cpu | head -10
echo -e "\n[USB]";      lsusb 2>/dev/null
echo "================================================================"
echo "                        END OF REPORT"
echo "================================================================"
REMOTE

        echo -e "${O}[*] Converting report to PDF...${NC}"
        if command -v enscript &>/dev/null && command -v ps2pdf &>/dev/null; then
            enscript -B -f Courier8 -p - "$TMP_TXT" 2>/dev/null | ps2pdf - "$OUT_PDF"
            rm -f "$TMP_TXT"
            echo -e "${G}[+] PDF report saved: $OUT_PDF${NC}"
        else
            apt-get install -y enscript ghostscript &>/dev/null
            enscript -B -f Courier8 -p - "$TMP_TXT" 2>/dev/null | ps2pdf - "$OUT_PDF"
            rm -f "$TMP_TXT"
            echo -e "${G}[+] PDF report saved: $OUT_PDF${NC}"
        fi
    done

    SUMMARY="$REMOTE_DIR/SUMMARY_$(date +%Y%m%d_%H%M%S).txt"
    { echo "=== MONITORING SUMMARY | $(date) | Machines: ${#MACHINES[@]} ==="; echo ""
      for ip in "${MACHINES[@]}"; do
          latest=$(ls -t "$REMOTE_DIR/${ip}_"*.pdf 2>/dev/null | head -1)
          echo ">>> $ip"
          [ -n "$latest" ] && echo "    PDF report: $(basename "$latest")" || echo "    No report (connection failed)"
          echo ""
      done; } > "$SUMMARY"

    echo -e "\n${G}[+] Summary: $SUMMARY${NC}"
    cat "$SUMMARY"
}

# ============================================================
#   MODULE 7 — CPU & RESOURCE ALERT SYSTEM
# ============================================================
run_cpu_alert() {
    clear
    echo -e "${OB}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${OB}║  CPU & RESOURCE ALERT SYSTEM${NC}  ${GR}$(date '+%Y-%m-%d %H:%M:%S')${OB}                    ║${NC}"
    echo -e "${OB}╚══════════════════════════════════════════════════════════════════════╝${NC}"

    THRESHOLD=80
    ALERT_LOG="$LOG_DIR/cpu_alerts.log"

    echo -e "\n${O}${BD}▶ CURRENT RESOURCE USAGE${NC}\n${OB}──────────────────────────────────────────────────────────────────────${NC}"

    CPU_USAGE=$(top -bn2 | grep 'Cpu(s)' | tail -1 | awk '{print int(100-$8)}')
    RAM_USAGE=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2*100}')
    DISK_USAGE=$(df / | awk 'NR==2 {print int($5)}')
    LOAD=$(awk '{print $1}' /proc/loadavg)

    echo -e "  ${BD}CPU Usage:${NC}  ${W}${CPU_USAGE}%${NC}"
    echo -e "  ${BD}RAM Usage:${NC}  ${W}${RAM_USAGE}%${NC}"
    echo -e "  ${BD}Disk Usage:${NC} ${W}${DISK_USAGE}%${NC}"
    echo -e "  ${BD}Load Avg:${NC}   ${W}${LOAD}${NC}"

    echo -e "\n${O}${BD}▶ ALERT CHECK (Threshold: ${THRESHOLD}%)${NC}\n${OB}──────────────────────────────────────────────────────────────────────${NC}"

    ALERT=0

    if [ "$CPU_USAGE" -ge "$THRESHOLD" ]; then
        echo -e "  ${R}⚠  WARNING: CPU usage is ${CPU_USAGE}% — exceeds ${THRESHOLD}% threshold!${NC}"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] CPU ALERT: ${CPU_USAGE}% on $(hostname)" >> "$ALERT_LOG"
        ALERT=1
    else
        echo -e "  ${G}✔  CPU OK: ${CPU_USAGE}% (below threshold)${NC}"
    fi

    if [ "$RAM_USAGE" -ge "$THRESHOLD" ]; then
        echo -e "  ${R}⚠  WARNING: RAM usage is ${RAM_USAGE}% — exceeds ${THRESHOLD}% threshold!${NC}"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] RAM ALERT: ${RAM_USAGE}% on $(hostname)" >> "$ALERT_LOG"
        ALERT=1
    else
        echo -e "  ${G}✔  RAM OK: ${RAM_USAGE}% (below threshold)${NC}"
    fi

    if [ "$DISK_USAGE" -ge "$THRESHOLD" ]; then
        echo -e "  ${R}⚠  WARNING: Disk usage is ${DISK_USAGE}% — exceeds ${THRESHOLD}% threshold!${NC}"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] DISK ALERT: ${DISK_USAGE}% on $(hostname)" >> "$ALERT_LOG"
        ALERT=1
    else
        echo -e "  ${G}✔  Disk OK: ${DISK_USAGE}% (below threshold)${NC}"
    fi

    # Send alert email if any threshold exceeded
    if [ "$ALERT" -eq 1 ] && command -v msmtp &>/dev/null; then
        echo -e "\n${O}[*] Sending alert email...${NC}"
        ALERT_CONF="/tmp/.msmtp_alert.conf"
        cat > "$ALERT_CONF" <<EOF
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
account        gmail
host           smtp.gmail.com
port           587
from           hassanhalis15@gmail.com
user           hassanhalis15@gmail.com
password       endz xdvs wcxb tcll
account default : gmail
EOF
        chmod 600 "$ALERT_CONF"
        printf "To: hashouay159@gmail.com\nFrom: hassanhalis15@gmail.com\nSubject: ALERT — High Resource Usage on $(hostname)\n\nCPU: ${CPU_USAGE}%%\nRAM: ${RAM_USAGE}%%\nDisk: ${DISK_USAGE}%%\nTime: $(date)\n" \
            | msmtp -C "$ALERT_CONF" hashouay159@gmail.com
        [ $? -eq 0 ] && echo -e "${G}[+] Alert email sent!${NC}" || echo -e "${R}[!] Alert email failed.${NC}"
        rm -f "$ALERT_CONF"
    fi

    echo -e "\n${O}${BD}▶ RECENT ALERT LOG${NC}\n${OB}──────────────────────────────────────────────────────────────────────${NC}"
    if [ -f "$ALERT_LOG" ]; then
        tail -5 "$ALERT_LOG" | while read -r line; do echo -e "  ${GR}$line${NC}"; done
    else
        echo -e "  ${GR}No alerts logged yet.${NC}"
    fi

    echo -e "\n${OB}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${OB}║  DONE${NC}  ${GR}$(date '+%Y-%m-%d %H:%M:%S')${OB}                                           ║${NC}"
    echo -e "${OB}╚══════════════════════════════════════════════════════════════════════╝${NC}"
}

# ============================================================
#   MODULE 8 — LOG INTEGRITY VERIFICATION (SHA256)
# ============================================================
run_integrity() {
    clear
    echo -e "${OB}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${OB}║  LOG INTEGRITY VERIFICATION — SHA256${NC}  ${GR}$(date '+%Y-%m-%d %H:%M:%S')${OB}            ║${NC}"
    echo -e "${OB}╚══════════════════════════════════════════════════════════════════════╝${NC}"

    HASH_FILE="$LOG_DIR/hashes.sha256"
    TARGETS=("$REPORT_DIR/full_report.pdf" "$REPORT_DIR/short_report.pdf" "$LOG_DIR/automation_$(date +%Y%m%d).log")

    echo -e "\n${O}${BD}▶ SELECT ACTION${NC}\n${OB}──────────────────────────────────────────────────────────────────────${NC}"
    echo -e "  ${W}[1]${NC} Generate hashes for current reports"
    echo -e "  ${W}[2]${NC} Verify reports against saved hashes"
    echo ""
    read -p "  Choice [1-2]: " ichoice

    case $ichoice in
        1)
            echo -e "\n${O}[*] Generating SHA256 hashes...${NC}"
            > "$HASH_FILE"
            for f in "${TARGETS[@]}"; do
                if [ -f "$f" ]; then
                    HASH=$(sha256sum "$f")
                    echo "$HASH" >> "$HASH_FILE"
                    echo -e "  ${G}✔${NC} $(basename "$f")"
                    echo -e "     ${GR}$(echo "$HASH" | awk '{print $1}')${NC}"
                else
                    echo -e "  ${R}✘ Not found: $(basename "$f")${NC}"
                fi
            done
            echo -e "\n${G}[+] Hashes saved to: $HASH_FILE${NC}"
            ;;
        2)
            if [ ! -f "$HASH_FILE" ]; then
                echo -e "\n${R}[!] No hash file found. Generate hashes first (option 1).${NC}"
                return
            fi
            echo -e "\n${O}[*] Verifying file integrity...${NC}"
            TAMPERED=0
            while IFS= read -r line; do
                FILE=$(echo "$line" | awk '{print $2}')
                if [ ! -f "$FILE" ]; then
                    echo -e "  ${R}✘ MISSING: $(basename "$FILE")${NC}"
                    TAMPERED=1
                else
                    CURRENT=$(sha256sum "$FILE" | awk '{print $1}')
                    SAVED=$(echo "$line" | awk '{print $1}')
                    if [ "$CURRENT" = "$SAVED" ]; then
                        echo -e "  ${G}✔ INTACT:${NC} $(basename "$FILE")"
                    else
                        echo -e "  ${R}⚠ TAMPERED: $(basename "$FILE")${NC}"
                        echo "[$(date '+%Y-%m-%d %H:%M:%S')] INTEGRITY FAIL: $FILE" >> "$LOG_DIR/cpu_alerts.log"
                        TAMPERED=1
                    fi
                fi
            done < "$HASH_FILE"
            [ $TAMPERED -eq 0 ] && echo -e "\n${G}[+] All files are intact.${NC}" || echo -e "\n${R}[!] Integrity issues detected!${NC}"
            ;;
        *)
            echo -e "${R}Invalid choice.${NC}"
            ;;
    esac

    echo -e "\n${OB}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${OB}║  DONE${NC}  ${GR}$(date '+%Y-%m-%d %H:%M:%S')${OB}                                           ║${NC}"
    echo -e "${OB}╚══════════════════════════════════════════════════════════════════════╝${NC}"
}

# ============================================================
#   MODULE 9 — REPORT COMPARISON (DETECT CHANGES)
# ============================================================
run_compare() {
    clear
    echo -e "${OB}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${OB}║  REPORT COMPARISON — DETECT CHANGES${NC}  ${GR}$(date '+%Y-%m-%d %H:%M:%S')${OB}             ║${NC}"
    echo -e "${OB}╚══════════════════════════════════════════════════════════════════════╝${NC}"

    SNAP_DIR="$LOG_DIR/snapshots"
    mkdir -p "$SNAP_DIR"

    echo -e "\n${O}${BD}▶ SELECT ACTION${NC}\n${OB}──────────────────────────────────────────────────────────────────────${NC}"
    echo -e "  ${W}[1]${NC} Take a new system snapshot"
    echo -e "  ${W}[2]${NC} Compare last two snapshots"
    echo ""
    read -p "  Choice [1-2]: " cchoice

    case $cchoice in
        1)
            SNAP_FILE="$SNAP_DIR/snapshot_$(date +%Y%m%d_%H%M%S).txt"
            echo -e "\n${O}[*] Taking system snapshot...${NC}"
            {
                echo "=== SYSTEM SNAPSHOT ==="
                echo "Date     : $(date)"
                echo "Hostname : $(hostname)"
                echo ""
                echo "[PACKAGES]"
                dpkg -l 2>/dev/null | grep '^ii' | awk '{print $2,$3}' | sort
                echo ""
                echo "[SERVICES]"
                systemctl list-units --type=service --state=running --no-legend 2>/dev/null | awk '{print $1}' | sort
                echo ""
                echo "[OPEN PORTS]"
                ss -tulpn 2>/dev/null | grep LISTEN | awk '{print $5}' | sort
                echo ""
                echo "[USERS]"
                cut -d: -f1 /etc/passwd | sort
                echo ""
                echo "[DISK USAGE]"
                df -h | grep -v tmpfs
            } > "$SNAP_FILE"
            echo -e "${G}[+] Snapshot saved: $(basename "$SNAP_FILE")${NC}"
            ;;
        2)
            SNAPS=($(ls -t "$SNAP_DIR"/snapshot_*.txt 2>/dev/null | head -2))
            if [ ${#SNAPS[@]} -lt 2 ]; then
                echo -e "\n${R}[!] Need at least 2 snapshots. Take more snapshots first.${NC}"
                return
            fi
            NEW="${SNAPS[0]}"; OLD="${SNAPS[1]}"
            echo -e "\n${O}[*] Comparing snapshots...${NC}"
            echo -e "  ${BD}OLD:${NC} ${GR}$(basename "$OLD")${NC}"
            echo -e "  ${BD}NEW:${NC} ${GR}$(basename "$NEW")${NC}"
            echo -e "\n${O}${BD}▶ DIFFERENCES${NC}\n${OB}──────────────────────────────────────────────────────────────────────${NC}"
            DIFF_OUT=$(diff "$OLD" "$NEW")
            if [ -z "$DIFF_OUT" ]; then
                echo -e "  ${G}✔  No changes detected between snapshots.${NC}"
            else
                echo "$DIFF_OUT" | while IFS= read -r line; do
                    if [[ "$line" == ">"* ]]; then
                        echo -e "  ${G}+ ${line:2}${NC}"
                    elif [[ "$line" == "<"* ]]; then
                        echo -e "  ${R}- ${line:2}${NC}"
                    else
                        echo -e "  ${GR}$line${NC}"
                    fi
                done
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Changes detected between snapshots" >> "$LOG_DIR/cpu_alerts.log"
            fi
            ;;
        *)
            echo -e "${R}Invalid choice.${NC}"
            ;;
    esac

    echo -e "\n${OB}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${OB}║  DONE${NC}  ${GR}$(date '+%Y-%m-%d %H:%M:%S')${OB}                                           ║${NC}"
    echo -e "${OB}╚══════════════════════════════════════════════════════════════════════╝${NC}"
}

# ============================================================
#   MAIN MENU
# ============================================================
main_menu() {
    while true; do
        clear
        echo -e "${OB}"
        echo "  ╔══════════════════════════════════════════════════════════╗"
        echo "  ║          SYSTEM AUDIT TOOLKIT  v2.0                      ║"
        echo "  ╠══════════════════════════════════════════════════════════╣"
        echo -e "  ║  ${W}[1]${OB} Hardware Audit          — CPU, GPU, RAM, Disks      ║"
        echo -e "  ║  ${W}[2]${OB} OS & Software Audit      — Services, Ports, Pkgs    ║"
        echo -e "  ║  ${W}[3]${OB} Generate PDF Reports     — Full & Short reports     ║"
        echo -e "  ║  ${W}[4]${OB} Send Reports by Email    — Gmail / App Password     ║"
        echo -e "  ║  ${W}[5]${OB} Automated Report + Send  — For cron / unattended    ║"
        echo -e "  ║  ${W}[6]${OB} Remote Monitoring (SSH)  — Multi-machine audit      ║"
        echo "  ╠══════════════════════════════════════════════════════════╣"
        echo -e "  ║  ${W}[7]${OB} CPU & Resource Alerts    — Auto alert if >80%       ║"
        echo -e "  ║  ${W}[8]${OB} Log Integrity Check      — SHA256 verification      ║"
        echo -e "  ║  ${W}[9]${OB} Compare Reports          — Detect system changes    ║"
        echo "  ╠══════════════════════════════════════════════════════════╣"
        echo -e "  ║  ${W}[0]${OB} Exit                                                ║"
        echo "  ╚══════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
        read -p "  Choice [0-9]: " choice

        case $choice in
            1) run_hardware      ;;
            2) run_os_software   ;;
            3) run_report        ;;
            4) run_send          ;;
            5) run_automation    ;;
            6) run_monitoring    ;;
            7) run_cpu_alert     ;;
            8) run_integrity     ;;
            9) run_compare       ;;
            0) echo -e "${G}Goodbye.${NC}"; exit 0 ;;
            *) echo -e "${R}Invalid choice.${NC}" ;;
        esac

        echo -e "\n${GR}Press Enter to return to menu...${NC}"
        read
    done
}

main_menu