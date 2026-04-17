#!/bin/bash

# Color Definitions (Original - Unmodified)
WHITE='\033[1;37m'
GREY='\033[0;90m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# Icons - Pre-rendered for stability
PASS_ICON=$(echo -e "${GREEN}✔${NC}")
FAIL_ICON=$(echo -e "${RED}✘${NC}")

# Global Status Log - Initialized as empty
STATUS_LOG=""

# Function to record status for the final summary
record_status() {
    local section_name="$1"
    local exit_code="$2"
    local error_msg="$3"

    if [ "$exit_code" -eq 0 ]; then
        STATUS_LOG="${STATUS_LOG}  ${PASS_ICON}  $(printf '%-30s' "$section_name") [${GREEN}SUCCESS${NC}]\n"
    else
        STATUS_LOG="${STATUS_LOG}  ${FAIL_ICON}  $(printf '%-30s' "$section_name") [${RED}ERROR: $error_msg${NC}]\n"
    fi
}

# Root Check
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}${BOLD}ERROR:${NC} This script must be run as root (sudo)."
   exit 1
fi

clear
echo -e "${CYAN}=========================================================================================${NC}"
echo -e "  ${BOLD}${WHITE}          OPERATING SYSTEM & SOFTWARE AUDIT REPORT${NC} | ${GREY}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${CYAN}=========================================================================================${NC}"

# 1. OS Info
echo -e "\n${BLUE}${BOLD}󰣆 OPERATING SYSTEM INFO${NC}"
echo -e "${RED}-----------------------------------------------------------------------------------------${NC}"
if [ -f /etc/os-release ]; then
    OS_NAME=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d '=' -f2 | tr -d '"')
    echo -e "  ${BOLD}OS Name:${NC}      ${BOLD}${WHITE}$OS_NAME${NC}"
else
    echo -e "  ${BOLD}OS Name:${NC}      ${BOLD}${WHITE}$(uname -s)${NC}"
fi
echo -e "  ${BOLD}Kernel:${NC}       ${BOLD}${WHITE}$(uname -r)${NC}"
echo -e "  ${BOLD}Architecture:${NC} ${BOLD}${WHITE}$(uname -m)${NC}"
echo -e "  ${BOLD}Hostname:${NC}     ${BOLD}${WHITE}$(hostname)${NC}"

# 2. Uptime & Load
echo -e "\n${BLUE}${BOLD}󱑎 SYSTEM UPTIME & LOAD${NC}"
echo -e "${RED}-----------------------------------------------------------------------------------------${NC}"
uptime_p=$(uptime -p 2>/dev/null)
if [ $? -eq 0 ]; then
    echo -e "  ${BOLD}System Uptime:${NC}  ${BOLD}${WHITE}$uptime_p${NC}"
    echo -e "  ${BOLD}Load:       ${NC}    ${BOLD}${WHITE}$(cat /proc/loadavg | awk '{print $1, $2, $3}')${NC}"
    record_status "System Uptime & Load" 0
else
    record_status "System Uptime & Load" 1 "Uptime command failed"
fi

# 3. Logged-in Users
echo -e "\n${BLUE}${BOLD}󰭹 LOGGED-IN USERS${NC}"
echo -e "${RED}-----------------------------------------------------------------------------------------${NC}"
if who > /dev/null; then
    who | while read -r line; do echo -e "  ${GREY}•${NC} ${BOLD}${WHITE}$line${NC}"; done
    record_status "Logged-in Users" 0
else
    record_status "Logged-in Users" 1 "No active sessions"
fi

# 4. Software Sources
echo -e "\n${BLUE}${BOLD}󰏆 SOFTWARE REPOSITORIES${NC}"
echo -e "${RED}-----------------------------------------------------------------------------------------${NC}"
if [ -r /etc/apt/sources.list ]; then
    # We use a while loop here to safely apply colors to each line
    grep -v '^#' /etc/apt/sources.list | grep '.' | head -n 3 | while read -r line; do
        echo -e "  • ${BOLD}${WHITE}$line${NC}"
    done
    record_status "Software Repositories" 0
else
    record_status "Software Repositories" 1 "Unreadable sources"
fi


# 5. Installed Packages
echo -e "\n${BLUE}${BOLD}󰏆 INSTALLED PACKAGES${NC}"
echo -e "${RED}-----------------------------------------------------------------------------------------${NC}"
if command -v dpkg &> /dev/null; then
    count=$(dpkg -l | grep -c "^ii")
    manager="dpkg/apt"
    echo -e "  ${BOLD}Manager:${NC} ${BOLD}${WHITE}$manager${NC}"
    echo -e "  ${BOLD}Total:${NC}   ${BOLD}${WHITE}$count installed packages${NC}"
    record_status "Installed Packages" 0
elif command -v rpm &> /dev/null; then
    count=$(rpm -qa | wc -l)
    manager="rpm/yum"
    echo -e "  ${BOLD}Manager:${NC} ${BOLD}${WHITE}$manager${NC}"
    echo -e "  ${BOLD}Total:${NC}   ${BOLD}${WHITE}$count installed packages${NC}"
    record_status "Installed Packages" 0
else
    record_status "Installed Packages" 1 "No known package manager found"
fi

# 6. Active Services
echo -e "\n${BLUE}${BOLD}󱖗 ACTIVE SERVICES${NC}"
echo -e "${RED}-----------------------------------------------------------------------------------------${NC}"
if command -v systemctl &> /dev/null; then
    total_svc=$(systemctl list-units --type=service --state=running --no-legend | wc -l)
    systemctl list-units --type=service --state=running --no-legend | head -n 5 | awk -v b="${BOLD}${WHITE}" -v n="${NC}" '{print "  • " b $1 n}'
    echo -e "  ${GREY}...and $total_svc total active services.${NC}"
    record_status "Active Services" 0
else
    record_status "Active Services" 1 "Systemd not detected"
fi

# 7. Top Processes
echo -e "\n${BLUE}${BOLD}󰓅 TOP PROCESSES${NC}"
echo -e "${RED}-----------------------------------------------------------------------------------------${NC}"
ps -eo pid,%mem,comm --sort=-%mem | head -n 6 | tail -n 5 | while read -r line; do
    echo -e "  ${BOLD}${WHITE}$line${NC}"
done
record_status "Top Processes" $? "Process error"
# 8. Network Ports
echo -e "\n${BLUE}${BOLD}󱔶 OPEN NETWORK PORTS${NC}"
echo -e "${RED}-----------------------------------------------------------------------------------------${NC}"
if command -v ss &> /dev/null; then
    ss -tulpn | grep LISTEN | head -n 5 | awk -v b="${BOLD}${WHITE}" -v n="${NC}" '{print "  • " b $5 " ("$1")" n}'
    record_status "Network Ports" 0
else
    record_status "Network Ports" 1 "ss tool missing"
fi

# --- THE FINAL SUMMARY SECTION ---
echo -e "\n${CYAN}-----------------------------------------------------------------------------------------${NC}"
echo -e "  ${BOLD}${WHITE}                                    Audit Status Summary${NC}"
echo -e "${CYAN}-----------------------------------------------------------------------------------------${NC}"
echo -e "$STATUS_LOG"
echo -e "${CYAN}=========================================================================================${NC}"
echo -e "  ${BOLD}${WHITE}AUDIT COMPLETE${NC} | ${GREY}Finished: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${CYAN}=========================================================================================${NC}"