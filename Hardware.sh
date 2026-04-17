#!/bin/bash

# color definition  

WHITE='\033[1;37m'  # white color 
GREY='\033[0;90m'   # grey color 
RED='\033[0;31m'    # red color
GREEN='\033[0;32m'  # green color
BLUE='\033[0;34m'   # blue color
CYAN='\033[0;36m'   # cyan color
YELLOW='\033[1;33m' # yellow color
BOLD='\033[1m'      # bold text
NC='\033[0m'        # No Color


# Root Check
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}${BOLD}ERROR:${NC} This script must be run as root (sudo) to access hardware tables."
   exit 1
fi

clear
echo -e "${CYAN}======================================================================${NC}"
echo -e "  ${BOLD}SYSTEM HARDWARE AUDIT REPORT${NC} | ${GREY}Generated: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${CYAN}======================================================================${NC}"

# 1. CPU
echo -e "\n${BLUE}${BOLD}󰻠 CPU INFORMATION${NC}"
echo -e "${RED}----------------------------------------------------------------------${NC}"
lscpu | grep -E 'Model name|Socket\(s\)|Core\(s\) per socket|Thread\(s\) per core|Architecture' | \
sed "s/:/: $(echo -e $WHITE)/" | \
sed "s/$/$(echo -e $NC)/" | \
sed 's/^/  /'


# 2. GPU
echo -e "\n${BLUE}${BOLD}󰢮 GPU INFORMATION${NC}"
echo -e "${RED}----------------------------------------------------------------------${NC}"
gpu_info=$(lspci | grep -iE 'vga|3d|display')
if [ -z "$gpu_info" ]; then
    echo -e "  ${RED}No discrete GPU detected.${NC}"
else
    echo -e "  ${WHITE}$gpu_info${NC}"
fi

# 3. RAM
echo -e "\n${BLUE}${BOLD}󰑭 RAM & MEMORY SLOTS${NC}"
echo -e "${RED}----------------------------------------------------------------------${NC}"
free -h | awk '/^Mem:/ {print "  \033[1mTotal/Available:\033[0m " $2 " / " $7}'
dmidecode -t memory | grep -E "Size|Type|Speed|Manufacturer" | grep -v "No Module Installed" | sed 's/^/  /'

# 4. DISK & FILESYSTEM
echo -e "\n${BLUE}${BOLD}󰋊 DISK & PARTITION LAYOUT${NC}"
echo -e "${RED}----------------------------------------------------------------------${NC}"
lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINT | sed 's/^/  /'

# 5. NETWORK (Updated with hostname -I)
echo -e "\n${BLUE}${BOLD}󰖩 NETWORK INTERFACES & IPS${NC}"
echo -e "${RED}----------------------------------------------------------------------${NC}"
nmcli device status 2>/dev/null | sed 's/^/  /' || ip -brief addr show | sed 's/^/  /'
echo -e "\n  ${BOLD}MAC Addresses:${NC}"
ip link show | grep link/ether | awk '{print "  - " $2}'

# Use hostname -I to get real local IPs
echo -e "  ${BOLD}Active IP Addresses:${NC} ${WHITE}$(hostname -I)${NC}"

# 6. MOTHERBOARD
echo -e "\n${BLUE}${BOLD}󰟀 MOTHERBOARD / CHASSIS${NC}"
echo -e "${RED}----------------------------------------------------------------------${NC}"
dmidecode -t baseboard | grep -E "Manufacturer|Product Name|Version|Serial Number" | sed 's/^/  /'
# 7. USB
echo -e "\n${BLUE}${BOLD}󱊟 CONNECTED USB DEVICES${NC}"
echo -e "${RED}----------------------------------------------------------------------${NC}"

# Simplified the sed command to prevent color bleeding and literal text printing
lsusb | cut -d ' ' -f 7- | while read -r line; do
    echo -e "  ${GREY}• ${WHITE}${line}${NC}"
done
echo -e "\n${CYAN}======================================================================${NC}"
echo -e "  ${WHITE}${BOLD}AUDIT COMPLETE${NC} | ${GREY}Finished: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${CYAN}======================================================================${NC}"