#!/bin/bash

# ============================================================
#   SYSTEM AUDIT TOOLKIT — Main Menu
# ============================================================

# Colors
W='\033[1;37m'; GR='\033[0;90m'; R='\033[0;31m'
G='\033[0;32m'; B='\033[0;34m'; C='\033[0;36m'
Y='\033[1;33m'; BD='\033[1m'; NC='\033[0m'
O='\033[0;33m'; OB='\033[1;33m'   # Orange / Bold Orange

 REMOTE_DIR="$REAL_HOME/reports/remote"
    mkdir -p "$REMOTE_DIR"

    command -v sshpass &>/dev/null || apt-get install -y sshpass &>/dev/null

    echo ""
    echo -e "${OB}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${OB}║              REMOTE MONITORING SETUP                                ║${NC}"
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