#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# --- CONFIGURATION: Set your credentials here ---
SENDER_GMAIL="rayenmezdoud@gmail.com"
SENDER_PASS="wzrcsdwblyszinpm"
RECIPIENT_EMAIL="mohrayen2324@gmail.com"

# --- PATHS ---
REPORT_SCRIPT="/home/medrayen/Desktop/Studies/Operating_sys/OS_Project/report.sh"
DESKTOP_PATH="/home/medrayen/Desktop"
REPORT_DIR="$DESKTOP_PATH/system_report"
SHORT_PDF="$REPORT_DIR/short_report.pdf"
FULL_PDF="$REPORT_DIR/full_report.pdf"
LOG_FILE="$REPORT_DIR/automation_send.log"  

# --- LOGGING HELPER ---
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# ============================================
# STEP 1: CHECK INTERNET CONNECTION
# ============================================
log "\e[34m[*] Checking internet connection...\e[0m"
if ! ping -c 1 8.8.8.8 &>/dev/null; then
    log "\e[31m[!] Error: No internet connection. Aborting.\e[0m"
    exit 1
fi
log "\e[32m[+] Internet connection OK.\e[0m"

# ============================================
# STEP 2: GENERATE REPORTS
# ============================================
log "\e[34m[*] Running report generation script...\e[0m"
bash "$REPORT_SCRIPT"

if [ $? -eq 0 ]; then
    log "\e[32m[+] Report generation: SUCCESS\e[0m"
else
    log "\e[31m[!] Report generation: FAILED. Aborting email send.\e[0m"
    exit 1
fi

# Safety check: confirm PDFs exist after generation
if [[ ! -f "$SHORT_PDF" || ! -f "$FULL_PDF" ]]; then
    log "\e[31m[!] PDF files not found after generation. Aborting.\e[0m"
    exit 1
fi

# ============================================
# STEP 3: SEND EMAIL
# ============================================
log "\e[34m[*] Sending reports to $RECIPIENT_EMAIL...\e[0m"

# Ensure msmtp is installed
if ! command -v msmtp &>/dev/null; then
    log "\e[33m[!] msmtp not found. Installing...\e[0m"
    sudo apt update && sudo apt install msmtp -y
fi

HOSTNAME=$(hostname)
MSMTP_CONF="/tmp/.msmtp_auto.conf"

# Write temporary msmtp config
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

SEND_STATUS=$?
rm -f "$MSMTP_CONF"

if [ $SEND_STATUS -eq 0 ]; then
    log "\e[32m[+] Success: Reports sent successfully to $RECIPIENT_EMAIL!\e[0m"
else
    log "\e[31m[!] Error: Email transmission failed. Check your App Password or connection.\e[0m"
    exit 1
fi