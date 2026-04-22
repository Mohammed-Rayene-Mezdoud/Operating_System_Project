# ⚙️ System Audit Toolkit

> **A modular Bash toolkit for comprehensive hardware & software auditing on Linux systems.**  
> Built for sysadmins, IT auditors, and OS students — dependency-light, terminal-native, and fully automatable.

---

## 1. Authors & License

| Field | Info |
|-------|------|
| 👤 Developed by | Mezdoud Mohammed Rayene & Halis Hassan |
| 📧 Contact | rayenmezdoud@gmail.com / hassanhalis15@gmail.com |
| 🏫 Section | B — Group 3 |
| 📅 Platform | Debian/Ubuntu Linux |
| 🛠️ Language | Bash Shell Script |
| 📄 License | Academic / Educational Use |


---


## 📋 Table of Contents
1. [Authors & License](#23-authors--license)
2. [Project Overview](#1-project-overview)
3. [Features](#2-features)
4. [Project Structure](#3-project-structure)
5. [Requirements](#4-requirements)
   - [Core Tools](#41-core-tools)
   - [Optional Tools](#42-optional-tools)
6. [Installation](#5-installation)
7. [Configuration](#6-configuration)
8. [Usage](#7-usage)
9. [Script Reference](#8-script-reference)
10. [Email Setup](#9-email-setup)
11. [Cron Automation](#10-cron-automation)
12. [Remote Monitoring Deep Dive](#11-remote-monitoring-deep-dive)
13. [PDF Report Anatomy](#12-pdf-report-anatomy)
14. [Security Considerations](#13-security-considerations)
15. [Troubleshooting](#14-troubleshooting)
16. [Known Limitations](#15-known-limitations)
17. [Compatibility Matrix](#16-compatibility-matrix)
18. [Data Flow Diagram](#17-data-flow-diagram)
19. [Output Files Reference](#18-output-files-reference)
20. [Environment Variables & Secrets Management](#19-environment-variables--secrets-management)
21. [Extending the Toolkit](#20-extending-the-toolkit)
22. [FAQ](#21-faq)
23. [Glossary](#22-glossary)


---

## 2. Project Overview

The **System Audit Toolkit** is a collection of **7 Bash scripts** offering **6 audit operations** via a single interactive launcher or a fully automated, unattended pipeline.

It collects system metrics, generates formatted PDF reports, and can deliver those reports via email — all without heavy dependencies or external agents.

Developed for system administrators, IT auditors, and students studying operating systems, the toolkit provides an accessible, self-contained solution for both local machine inspection and multi-host remote monitoring.

| Goal | Description |
|------|-------------|
| 🖥️ Hardware Inventory | Enumerate CPU, GPU, RAM slots, disks, USB devices, and network adapters |
| 🧩 Software Audit | Inspect OS, running services, open ports, installed packages, and top processes |
| 📄 PDF Reporting | Produce a detailed full report and a concise executive summary as PDF files |
| 📧 Email Delivery | Transmit PDF attachments via Gmail SMTP using an App Password |
| 🌐 Remote Monitoring | SSH into multiple remote hosts and collect full audit data, saved as PDF |
| 🤖 Full Automation | Chain report generation and email dispatch without user interaction |

---

## 3. Features

### ✅ Core Features

- **Interactive TUI Menu** — Full-screen terminal UI with numbered options 1–6; no flags required.
- **Hardware Audit** — Detailed inventory: CPU topology, GPU detection, RAM slot mapping, disk partitions, network adapters, USB devices, and motherboard/BIOS info.
- **Software & OS Audit** — Kernel version, uptime, active services, open ports, installed package count, top processes by RAM, and per-section pass/fail status reporting.
- **Dual PDF Reports** — Automatically generates two PDFs:
  - `full_report.pdf` — exhaustive multi-section audit document.
  - `short_report.pdf` — executive summary fit for quick review or management sharing.
- **Email Delivery** — Sends both PDF attachments to any recipient via Gmail SMTP with MIME multipart encoding.
- **Multi-Host Remote Monitoring** — SSH into any number of remote Linux machines in a single session; save per-machine PDFs and a consolidated session summary.
- **Full Unattended Automation** — Pre-configured pipeline for cron scheduling: check connectivity → generate PDFs → email → log.

### 🌟 Additional Highlights

- **Auto-installs missing dependencies** — Scripts detect and install `enscript`, `ghostscript`, `msmtp`, and `sshpass` via `apt-get` on first run.
- **Real-user ownership preservation** — `Report.sh` detects the invoking user even under `sudo` and sets correct file ownership on all generated PDFs.
- **Secure temporary credential handling** — `Send.sh` writes msmtp config to `/tmp` with `chmod 600` and deletes it immediately after transmission.
- **Timestamped logging** — `Automation.sh` appends every pipeline step to a structured log file for audit trail purposes.
- **Fallback detection paths** — Scripts attempt alternative commands (`lshw -C display`) when primary detection fails.
- **Color-coded terminal output** — All terminal reports use ANSI colors for instant readability; PDF output is clean monochrome text.

---

## 4. Project Structure

All scripts are **self-contained** and must reside in the **same directory**. `Launcher.sh` locates sibling scripts at runtime via `SCRIPT_DIR` — no hardcoded paths required.

```
~/Desktop/OS_Project/
├── Launcher.sh       ← Interactive TUI menu — main entry point
├── Hardware.sh       ← Local hardware audit (requires root)
├── Software.sh       ← OS & software audit (requires root)
├── Report.sh         ← PDF report generation (requires root)
├── Send.sh           ← Email delivery via Gmail SMTP (requires root)
├── Monitoring.sh     ← Remote machine monitoring via SSH
└── Automation.sh     ← Fully unattended pipeline (requires root)
```

### Generated Output Directories

```
~/Desktop/system_report/
├── full_report.pdf             ← Detailed hardware + software report
├── short_report.pdf            ← Executive summary
└── automation_send.log         ← Automation pipeline log (timestamped)

~/reports/remote/
├── <IP>_<timestamp>.pdf        ← Per-machine remote audit PDF
├── SUMMARY_<timestamp>.pdf     ← Consolidated session summary
└── remote_monitor.log          ← SSH monitoring log
```

| Script | Role | Root Required |
|--------|------|:---:|
| `Launcher.sh` | Interactive TUI menu — main entry point for all operations | ✅ |
| `Hardware.sh` | Local hardware audit: CPU, GPU, RAM, disk, network, motherboard, USB | ✅ |
| `Software.sh` | OS & software audit: services, ports, packages, processes, uptime | ✅ |
| `Report.sh` | Generates `full_report.pdf` and `short_report.pdf` on the Desktop | ✅ |
| `Send.sh` | Sends the PDF reports to a recipient via Gmail SMTP (msmtp) | ✅ |
| `Monitoring.sh` | Connects to remote machines via SSH and saves audit data as PDF | ❌ |
| `Automation.sh` | Non-interactive pipeline: generates reports and emails them automatically | ✅ |

---

## 5. Requirements

### 5.1 Core Tools

These tools are **required** for primary functionality. The toolkit will attempt to auto-install missing packages on first run (Debian/Ubuntu only).

| Tool | Package Name | Used By | Purpose |
|------|-------------|---------|---------|
| `enscript` | `enscript` | Report.sh, Send.sh, Monitoring.sh | Converts plain text to PostScript |
| `ghostscript` | `ghostscript` | Report.sh, Send.sh, Monitoring.sh | Converts PostScript to PDF (`ps2pdf`) |
| `msmtp` | `msmtp` | Send.sh, Automation.sh | Lightweight SMTP client for Gmail |
| `sshpass` | `sshpass` | Monitoring.sh | Non-interactive SSH password authentication |
| `nmcli` | `network-manager` | Hardware.sh, Report.sh, Send.sh | Reads Wi-Fi SSID and interface status |
| `dmidecode` | `dmidecode` | Hardware.sh, Report.sh | Reads BIOS, RAM slots, motherboard info from DMI tables |
| `lsblk` | *(built-in)* | Hardware.sh, Software.sh | Lists block devices and partitions |
| `ss` | `iproute2` | Hardware.sh, Software.sh | Lists open network sockets/ports |

**Install all core tools at once:**

```bash
sudo apt update && sudo apt install enscript ghostscript msmtp sshpass -y
```

### 5.2 Optional Tools

These tools extend functionality but are **not required** for basic operation. Scripts will degrade gracefully or skip the relevant section if they are absent.

| Tool | Package Name | Used By | Purpose | Without It |
|------|-------------|---------|---------|-----------|
| `lshw` | `lshw` | Monitoring.sh | Full hardware tree on remote hosts | Hardware tree section skipped |
| `upower` | `upower` | Report.sh, Send.sh | Battery status information | Displays "No Battery Detected" |
| `curl` | `curl` | Report.sh, Send.sh | Fetches public IP via `ifconfig.me` | Public IP section left blank |
| `iostat` | `sysstat` | Monitoring.sh | Disk I/O statistics on remote hosts | I/O stats section skipped |
| `nvidia-smi` | *(NVIDIA driver)* | Monitoring.sh | GPU utilization percentage | Only GPU name shown, no utilization |
| `sensors` | `lm-sensors` | Monitoring.sh | CPU/GPU temperature readings | Temperature section skipped |
| `smartctl` | `smartmontools` | Monitoring.sh | Disk SMART health status | SMART health section skipped |

**Install all optional tools at once:**

```bash
sudo apt update && sudo apt install lshw upower curl sysstat lm-sensors smartmontools -y
```

---

## 6. Installation

### Step 1 — Clone or Download

Download or clone all seven script files into a single directory:

```bash
# Option A: Clone from a repository
git clone https://github.com/your-repo/system-audit-toolkit.git ~/Desktop/OS_Project

# Option B: Copy files manually
mkdir -p ~/Desktop/OS_Project
cp *.sh ~/Desktop/OS_Project/
```

### Step 2 — Navigate to the Directory

```bash
cd ~/Desktop/OS_Project
```

### Step 3 — Make All Scripts Executable

```bash
chmod +x *.sh
```

Verify permissions:

```bash
ls -la *.sh
# Expected: -rwxr-xr-x for each script
```

### Step 4 — Install Dependencies

```bash
# Core (required)
sudo apt update && sudo apt install enscript ghostscript msmtp sshpass -y

# Optional (recommended)
sudo apt install lshw upower curl sysstat lm-sensors smartmontools -y
```

> 💡 **Tip:** If you skip manual dependency installation, scripts will attempt to auto-install missing packages the first time they are run — but you will need an active internet connection.

### Step 5 — Verify Installation

```bash
# Quick sanity check
sudo bash Launcher.sh
```

If the TUI menu appears, installation is complete.

---

## 7. Configuration

### 7.1 Automation Credentials

Before using **Option 6 (Full Automation)** or scheduling with cron, open `Automation.sh` and configure the three credential variables at the top of the file:

```bash
nano Automation.sh
```

```bash
# ─── CONFIGURE THESE THREE VARIABLES ───────────────────────────
SENDER_GMAIL="your.address@gmail.com"        # Gmail used to send reports
SENDER_PASS="xxxx xxxx xxxx xxxx"            # 16-char Gmail App Password
RECIPIENT_EMAIL="recipient@example.com"      # Where reports are delivered
# ────────────────────────────────────────────────────────────────
```

| Variable | What to Set | Example |
|----------|-------------|---------|
| `SENDER_GMAIL` | Your Gmail address used to send reports | `audit@gmail.com` |
| `SENDER_PASS` | A 16-character Gmail App Password *(not your login password)* | `abcd efgh ijkl mnop` |
| `RECIPIENT_EMAIL` | The destination email for audit PDF reports | `admin@company.com` |

> ⚠️ **Security Note:** Never commit `Automation.sh` with real credentials to a public repository.  
> See [Section 19 — Environment Variables & Secrets Management](#19-environment-variables--secrets-management) for safer alternatives.

### 7.2 Restrict Credential File Permissions

After setting credentials, restrict file permissions to prevent other users from reading them:

```bash
chmod 600 Automation.sh
```

### 7.3 Verifying msmtp

To test email delivery before scheduling with cron:

```bash
echo "Test" | msmtp --debug your-recipient@example.com
```

---

## 8. Usage

### 8.1 Launching the Interactive Menu

The recommended entry point for all operations:

```bash
sudo bash Launcher.sh
```

A full-screen TUI menu appears with numbered options **1–6**. Use the keyboard to select an action, then press `Enter`. After each operation completes, press `Enter` again to return to the menu.

### 8.2 Menu Options

#### `[1]` Hardware Audit

Runs `Hardware.sh`. Displays a **color-coded terminal report** covering:

- CPU model, socket count, cores per socket, thread count, architecture
- GPU detection via `lspci`
- RAM total/available + physical slot details
- Disk partitions with filesystem types and mount points
- Network interfaces, MAC addresses, and active IPs
- Motherboard manufacturer, product name, version, and serial number
- All connected USB devices

```bash
# Run directly (alternative to menu):
sudo bash Hardware.sh
```

#### `[2]` OS & Software Audit

Runs `Software.sh`. Shows:

- OS pretty name, kernel version, architecture, hostname
- Uptime and system load averages
- Currently logged-in users
- Software repositories (first 3 non-comment entries from `/etc/apt/sources.list`)
- Total installed package count
- Top 5 active services (with total service count)
- Top 5 processes by RAM consumption
- All LISTEN sockets (open network ports)
- **Pass/fail status summary table** at the end

```bash
sudo bash Software.sh
```

#### `[3]` Generate PDF Reports

Runs `Report.sh`. Creates two PDF files in `~/Desktop/system_report/`:

| File | Description |
|------|-------------|
| `full_report.pdf` | Six sections: hardware, RAM, network, motherboard, software/security, battery |
| `short_report.pdf` | Executive summary: hostname, uptime, CPU/GPU, memory, disk, users, top processes, network |

The output folder **opens automatically** after generation.

```bash
sudo bash Report.sh
```

#### `[4]` Send Reports by Email

Runs `Send.sh`. Prompts interactively for:

1. Gmail address (sender)
2. Gmail App Password (16 characters)
3. Recipient email address

Auto-generates reports if they don't yet exist, then transmits both PDFs as MIME attachments.

```bash
sudo bash Send.sh
```

#### `[5]` Remote Machine Monitoring

Runs `Monitoring.sh`. Prompts for:

1. Number of remote machines to monitor
2. For each machine: IP address, SSH username, SSH password

Connects via SSH, runs a comprehensive remote audit, and saves results as timestamped PDF files in `~/reports/remote/`.

```bash
bash Monitoring.sh
```

#### `[6]` Full Automation

Runs `Automation.sh`. **No interactive prompts.** Executes three pipeline steps:

1. Checks internet connectivity (pings `8.8.8.8`)
2. Generates both PDF reports via `Report.sh`
3. Emails them to the pre-configured recipient

Logs every step with timestamps to `~/Desktop/system_report/automation_send.log`.

```bash
sudo bash Automation.sh
```

### 8.3 Running Scripts Directly

Any script can be run independently outside the launcher:

```bash
sudo bash Hardware.sh      # Hardware audit only
sudo bash Software.sh      # Software audit only
sudo bash Report.sh        # Generate PDFs only
sudo bash Send.sh          # Email reports only
bash Monitoring.sh         # Remote monitoring only
sudo bash Automation.sh    # Full unattended pipeline
```

---

## 9. Script Reference

### `Launcher.sh`

The central TUI menu. Locates all sibling scripts at runtime using `SCRIPT_DIR` (resolved from the script's own path). Validates root privileges where required, delegates execution to the chosen script, and handles the press-Enter pause after each operation completes.

---

### `Hardware.sh` ⚠️ Requires root

Performs a local hardware audit. Must be run as root (or via `sudo`) to access `dmidecode` hardware tables. Outputs to terminal with ANSI color codes.

**Sections reported:**

| Section | Command(s) Used | Details Captured |
|---------|----------------|-----------------|
| CPU | `lscpu`, `dmidecode` | Model, socket count, cores per socket, threads, architecture |
| GPU | `lspci` | VGA / 3D / display-class devices |
| RAM | `free`, `dmidecode` | Total/available memory + physical slot details |
| Disk & Partitions | `lsblk` | Device name, size, filesystem type, mount point |
| Network | `nmcli`, `hostname -I` | Interface status, MAC addresses, active IPs |
| Motherboard / Chassis | `dmidecode` | Manufacturer, product name, version, serial |
| USB Devices | `lsusb` | All connected USB devices |

---

### `Software.sh` ⚠️ Requires root

Audits the operating system layer. Each section records a **pass or fail** status; the final summary table aggregates all statuses.

**Sections reported:**

| Section | Command(s) Used | Pass Condition |
|---------|----------------|----------------|
| Operating System | `/etc/os-release` | OS info retrievable |
| Uptime & Load | `uptime`, `/proc/loadavg` | Uptime data available |
| Logged-in Users | `who` | Command executes successfully |
| Software Repositories | `/etc/apt/sources.list` | At least one active repo found |
| Installed Packages | `dpkg`, `rpm` | Package manager returns count |
| Active Services | `systemctl` | Service list retrieved |
| Top Processes | `ps` | Process list available |
| Open Network Ports | `ss -tulpn` | Socket list retrieved |

---

### `Report.sh` ⚠️ Requires root

Generates two structured audit reports and converts them to PDF using `enscript` + `ps2pdf`. Detects the real user even when invoked via `sudo` (via `$SUDO_USER` or `logname`), and sets correct file ownership with `chown`.

**PDF Pipeline:**

```
Raw Data Collection → Formatted Text → enscript (PostScript) → ps2pdf (PDF) → chown to real user
```

**Output files** (saved to `~/Desktop/system_report/`):

| File | Sections Included |
|------|------------------|
| `full_report.pdf` | Hardware, RAM, Network, Motherboard, Software/Security, Battery |
| `short_report.pdf` | Hostname, Uptime, CPU/GPU, Memory, Disk, Users, Top Processes, Network |

---

### `Send.sh` ⚠️ Requires root

Sends both PDF reports to a recipient via Gmail SMTP. Validates email format with a regex check, verifies internet connectivity, auto-generates missing reports, writes a temporary msmtp configuration to `/tmp/.msmtp_tmp.conf` (mode `600`), transmits the email, then **deletes the config file immediately**.

**Email composition:**

| Field | Value |
|-------|-------|
| Subject | `System Audit Results: <hostname>` |
| Body | Plain text with generation timestamp |
| Attachments | `short_report.pdf` and `full_report.pdf` (base64-encoded, multipart/mixed MIME) |
| SMTP Host | `smtp.gmail.com` |
| SMTP Port | `587` (STARTTLS) |

---

### `Monitoring.sh`

Connects to one or more remote Linux machines via SSH (password authentication using `sshpass`) and runs a comprehensive remote audit. Results are saved as timestamped PDF files per machine, plus a consolidated summary PDF.

**Remote data collected:**

| Category | Data Points |
|----------|-------------|
| Operating System | `os-release`, kernel, uptime, logged-in users, last logins |
| CPU | Model, usage percentage, temperature, top 5 processes by CPU |
| RAM | `free -h` overview, `/proc/meminfo`, `dmidecode` slot info, top 5 by RAM |
| Motherboard | Baseboard, BIOS version, system manufacturer |
| Disk & Storage | `df`, `lsblk`, `fdisk`, `iostat`, SMART health status |
| Network | Interfaces/IPs, routing table, DNS servers, traffic counters, open ports, active connections, failed SSH logins |
| USB & Devices | `lsusb`, block devices, input devices |
| Hardware Summary | `lshw`, `lspci`, GPU info, sensor readings |
| Software | Installed packages, recent installs, running/enabled services, pending security updates, crontab entries |

**Output files:**

| File | Path |
|------|------|
| Per-machine report | `~/reports/remote/<IP>_<timestamp>.pdf` |
| Session summary | `~/reports/remote/SUMMARY_<timestamp>.pdf` |
| Session log | `~/reports/remote_monitor.log` |

---

### `Automation.sh` ⚠️ Requires root

A fully unattended pipeline. Requires credentials to be pre-configured in the script. Designed for **scheduled execution via cron**. Every action is logged with timestamps to `automation_send.log`.

**Pipeline steps:**

| Step | Action | Abort on Failure? |
|------|--------|:-----------------:|
| 1 | Checks internet connectivity by pinging `8.8.8.8` | ✅ |
| 2 | Calls `Report.sh` to generate both PDFs | ✅ |
| 3 | Verifies both PDFs exist on disk | ✅ |
| 4 | Writes temporary msmtp config (`chmod 600`) | ✅ |
| 5 | Transmits email with both PDF attachments | ✅ |
| 6 | Deletes temporary msmtp config | ❌ |

---

## 10. Email Setup

### 10.1 Why a Gmail App Password?

Gmail blocks "less secure app access" by default. To send email programmatically via SMTP, you must use a **Gmail App Password** — a 16-character token separate from your account password. This requires 2-Step Verification to be enabled on your Google account.

### 10.2 Creating a Gmail App Password

1. Go to **myaccount.google.com**
2. Navigate to **Security → 2-Step Verification** (enable if not already active)
3. Scroll to **App passwords** at the bottom of the 2-Step Verification page
4. Select **Mail** as the app and **Other** as the device; name it "System Audit"
5. Click **Generate** — Google displays a **16-character password**
6. Copy it immediately (it will not be shown again)

### 10.3 Using the App Password

**In `Send.sh` (interactive):** Enter the 16-character password when prompted.

**In `Automation.sh` (unattended):** Paste it into the `SENDER_PASS` variable (spaces are fine):

```bash
SENDER_PASS="abcd efgh ijkl mnop"
```

### 10.4 How msmtp Is Configured

`Send.sh` and `Automation.sh` write a temporary msmtp config to `/tmp/.msmtp_tmp.conf`:

```ini
account default
host smtp.gmail.com
port 587
from YOUR_GMAIL
auth on
user YOUR_GMAIL
password YOUR_APP_PASSWORD
tls on
tls_starttls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile /tmp/msmtp.log
```

This file is created with `chmod 600` and **deleted immediately** after the email is sent.

### 10.5 Testing Email Delivery Manually

```bash
echo "Test body" | msmtp \
  --host=smtp.gmail.com \
  --port=587 \
  --auth=on \
  --user=your@gmail.com \
  --passwordeval="echo 'yourapppassword'" \
  --tls=on \
  recipient@example.com
```

---

## 11. Cron Automation

`Automation.sh` is designed to run fully unattended and is ideal for scheduled execution via cron.

### 11.1 Opening Root Crontab

```bash
sudo crontab -e
```

### 11.2 Example Cron Schedules

```cron
# Run every day at 08:00
0 8 * * * /path/to/Automation.sh >> /var/log/audit_cron.log 2>&1

# Run every Monday at 06:30
30 6 * * 1 /path/to/Automation.sh >> /var/log/audit_cron.log 2>&1

# Run on the 1st of every month at midnight
0 0 1 * * /path/to/Automation.sh >> /var/log/audit_cron.log 2>&1

# Run every 6 hours
0 */6 * * * /path/to/Automation.sh >> /var/log/audit_cron.log 2>&1
```

### 11.3 Cron Field Reference

```
┌─────── minute   (0–59)
│ ┌───── hour     (0–23)
│ │ ┌─── day      (1–31)
│ │ │ ┌─ month    (1–12)
│ │ │ │ ┌ weekday (0–7, 0 and 7 = Sunday)
│ │ │ │ │
* * * * *  /path/to/Automation.sh
```

### 11.4 Verifying Cron Is Running

```bash
# Check cron service status
sudo systemctl status cron

# View cron system log
grep CRON /var/log/syslog | tail -20

# View your custom log
tail -f /var/log/audit_cron.log
```

### 11.5 Important Cron Considerations

- Cron runs with a **minimal environment** — always use **absolute paths** in the cron entry.
- The `PATH` variable in cron is limited; if scripts fail silently, prefix with:  
  ```cron
  PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
  ```
- Cron jobs run as the user whose crontab they are in; use `sudo crontab -e` to run as root.
- Redirect both stdout and stderr: `>> /var/log/audit_cron.log 2>&1`

---

## 12. Remote Monitoring Deep Dive

### 12.1 How Monitoring.sh Works

```
User Input (IPs, credentials)
        ↓
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no user@host
        ↓
Remote commands executed over SSH → stdout captured to local .txt file
        ↓
enscript -B (text → Courier 8pt PostScript)
        ↓
ps2pdf (PostScript → PDF)
        ↓
PDF saved to ~/reports/remote/<IP>_<timestamp>.pdf
        ↓
Intermediate .txt file deleted
        ↓
Consolidated SUMMARY_<timestamp>.pdf generated
```

### 12.2 Network Requirements

| Requirement | Detail |
|-------------|--------|
| SSH access | Port 22 must be open and reachable on each remote host |
| SSH server | `openssh-server` must be running on the remote machine |
| Firewall | Remote firewall must allow inbound SSH connections |
| Credentials | Valid username and password for each remote host |

### 12.3 Required Remote Host Software

For full data collection, the following should be available on each remote machine:

```bash
# Recommended: install on remote hosts
sudo apt install lshw dmidecode sysstat smartmontools lm-sensors -y
```

### 12.4 Security Warning

`Monitoring.sh` uses `sshpass` with `-o StrictHostKeyChecking=no`, which disables host key verification. This is appropriate **only on trusted private networks** (e.g., a lab environment). For production use, replace password authentication with SSH key pairs:

```bash
# Generate key pair (on local machine)
ssh-keygen -t ed25519 -C "audit-key"

# Copy public key to each remote host
ssh-copy-id user@remote-host-ip

# Then modify Monitoring.sh to use key auth instead of sshpass
```

---

## 13. PDF Report Anatomy

### 13.1 full_report.pdf — Section Breakdown

| Section | Contents |
|---------|----------|
| 1. System Header | Hostname, date/time of report generation, OS version |
| 2. Hardware | CPU topology, GPU, RAM total/available, slot details |
| 3. Network | Interface status, active IPs, public IP, Wi-Fi SSID |
| 4. Motherboard | Manufacturer, product, version, serial number, BIOS info |
| 5. Software & Security | Kernel version, active services count, open ports, top processes |
| 6. Battery | Battery status via `upower` (or "No Battery Detected") |

### 13.2 short_report.pdf — Section Breakdown

| Section | Contents |
|---------|----------|
| Summary Header | Hostname, generation timestamp |
| System Info | OS name, kernel, architecture, uptime |
| CPU & GPU | Model names, core/thread counts |
| Memory | Total, used, available RAM |
| Disk | Filesystem usage summary |
| Users | Currently logged-in users |
| Top Processes | Top 5 processes by RAM |
| Network | Primary interface and IP |

### 13.3 PDF Generation Pipeline

```
Data Collection (Bash commands)
          ↓
Formatted plain text (echo, printf)
          ↓
enscript -B --output=- (→ PostScript, Courier 8pt)
          ↓
ps2pdf - output.pdf (→ PDF via Ghostscript)
          ↓
chown $REAL_USER output.pdf (correct file ownership)
          ↓
xdg-open ~/Desktop/system_report/ (folder auto-opens)
```

> **Note:** ANSI color codes present in terminal output are automatically stripped during the text-to-PostScript conversion. PDF reports are always clean monochrome text.

---

## 14. Security Considerations

### 14.1 Credential Handling

| Risk | Mitigation |
|------|-----------|
| `Automation.sh` stores App Password in plaintext | Run `chmod 600 Automation.sh` to restrict read access |
| `Send.sh` temporarily stores credentials on disk | Config written to `/tmp` with `chmod 600`; deleted immediately after use |
| Credentials in version control | Never commit credential-containing scripts to public repos |

**Recommended safer approach:** Use environment variables instead of hardcoded values:

```bash
# In your shell profile or /etc/environment:
export AUDIT_GMAIL="your@gmail.com"
export AUDIT_PASS="yourapppassword"
export AUDIT_RECIPIENT="admin@company.com"
```

Then reference them in `Automation.sh`:

```bash
SENDER_GMAIL="${AUDIT_GMAIL}"
SENDER_PASS="${AUDIT_PASS}"
RECIPIENT_EMAIL="${AUDIT_RECIPIENT}"
```

### 14.2 SSH / Remote Monitoring

- `Monitoring.sh` uses `sshpass` with `-o StrictHostKeyChecking=no` — disables host key verification; appropriate only on **trusted private networks**.
- Remote machine passwords exist only in shell variables; they are **never written to disk**.
- For production use, replace password auth with **SSH key pairs** (see [Section 11.4](#114-security-warning)).

### 14.3 Root Privilege

| Script | Root Required | Reason |
|--------|:---:|--------|
| `Hardware.sh` | ✅ | `dmidecode` requires root for DMI table access |
| `Software.sh` | ✅ | `ss`, `systemctl` output full data only under root |
| `Report.sh` | ✅ | Needs root-level data; uses `chown` to correct ownership |
| `Send.sh` | ✅ | Report generation and system data collection |
| `Automation.sh` | ✅ | All of the above |
| `Monitoring.sh` | ❌ | Local: no root needed. Remote: root may be needed on target host |

### 14.4 Principle of Least Privilege

For production deployments, consider limiting the scope of access:

- Create a **dedicated audit user** with `sudo` access restricted to only the necessary commands.
- Use an **App Password** with a dedicated Gmail account created solely for audit purposes.
- **Rotate the App Password** periodically and whenever team members with access leave.

---

## 15. Troubleshooting

| Symptom | Likely Cause | Remedy |
|---------|-------------|--------|
| Email fails with authentication error | Wrong password type | Use a **Gmail App Password** (16 chars), not your login password. 2-Step Verification must be enabled. |
| Email sends but no attachment received | Report files missing | Run Option 3 (Generate PDF Reports) before Option 4 (Send). |
| PDF files not created | Missing dependencies | Run: `sudo apt install enscript ghostscript` |
| `Hardware.sh` shows no GPU | Integrated GPU not detected by `lspci` | Run `lshw -C display` for alternative GPU detection. |
| `Monitoring.sh`: SSH connection failed | Network/credential issue | Verify IP, username, password. Check: `sudo systemctl status ssh` on the remote host. Ensure port 22 is open. |
| `dmidecode` returns empty output | Not running as root | Run script with `sudo`. Note: some virtualised environments restrict DMI table access regardless. |
| `msmtp` not found | Package not installed | Auto-installs on next run, or manually: `sudo apt install msmtp` |
| `sshpass` not found | Package not installed | Auto-installs on next run, or manually: `sudo apt install sshpass` |
| Script not found error in Launcher | Scripts in different directories | All scripts must be in the **same directory** as `Launcher.sh`. Filenames are case-sensitive. |
| Cron job runs but no email sent | Cron PATH issue | Use absolute paths in crontab. Add `PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin` at the top of the crontab. |
| `Report.sh` creates PDFs owned by root | Real user not detected | Check that `$SUDO_USER` is set; try running with `sudo -E bash Report.sh` |
| Remote PDF is empty or malformed | Remote command returned no data | SSH manually to the target and verify commands work: `ssh user@host "lscpu"` |
| TUI menu displays garbled characters | Terminal encoding issue | Ensure your terminal uses UTF-8: `export LANG=en_US.UTF-8` |
| `lshw` not found on remote host | Package not installed remotely | On the remote host: `sudo apt install lshw` |
| Battery section shows "No Battery Detected" | Desktop/server without battery | Expected behavior. Install `upower` if not present on laptop systems. |

---

## 16. Known Limitations

- 🐧 **Debian/Ubuntu only** — Designed for Debian/Ubuntu-based Linux distributions. RPM-based systems (RHEL, Fedora, CentOS) may require adaptations for `dnf`/`rpm` package manager commands.
- 🎮 **GPU utilization** — GPU usage percentage requires proprietary **NVIDIA drivers** (`nvidia-smi`). AMD and Intel integrated GPUs report only the device name, not real-time utilization.
- 🔐 **Password-based SSH** — `Monitoring.sh` uses password-based SSH authentication, which is less secure than key-based auth. Intended for lab and controlled environments only.
- 🎨 **Monochrome PDFs** — PDF reports strip ANSI color codes. Terminal output of `Hardware.sh` and `Software.sh` is always color-coded; generated PDFs are plain monochrome text.
- 🔋 **Battery detection** — The battery section requires `upower` and will display "No Battery Detected" on desktops or servers without a battery.
- 🌐 **Public IP detection** — Requires an active internet connection and access to `ifconfig.me`. Fails silently on isolated networks.
- 📦 **Auto-install requires internet** — Dependency auto-installation requires internet and `apt` access. Offline systems must pre-install all dependencies manually.
- 🔒 **Virtualisation restrictions** — Some hypervisors (e.g., certain cloud VMs) block `dmidecode` access, resulting in empty hardware sections even with root privileges.
- 📧 **Gmail only** — The email delivery scripts are configured for Gmail SMTP only. Other email providers (Outlook, Yahoo, self-hosted) would require modifying the SMTP host, port, and TLS settings in `Send.sh` and `Automation.sh`.

---

## 17. Compatibility Matrix

| Feature | Ubuntu 20.04 | Ubuntu 22.04 | Ubuntu 24.04 | Debian 11 | Debian 12 | RHEL/Fedora |
|---------|:---:|:---:|:---:|:---:|:---:|:---:|
| Hardware Audit | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| Software Audit | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| PDF Generation | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| Email Delivery | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| Remote Monitoring | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| Full Automation | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| Auto-install deps | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| GPU % (NVIDIA) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Battery (laptop) | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |

> ✅ Fully supported · ⚠️ Partial support (manual adaptation required) · ❌ Not supported

---

## 18. Data Flow Diagram

### Local Audit Flow

```
sudo bash Launcher.sh
         │
         ├─[1]─► Hardware.sh ──────────────────► Terminal (ANSI color)
         │
         ├─[2]─► Software.sh ─────────────────► Terminal + pass/fail table
         │
         ├─[3]─► Report.sh ──► enscript ──► ps2pdf ──► full_report.pdf
         │                                          └──► short_report.pdf
         │
         ├─[4]─► Send.sh ──► msmtp (Gmail SMTP) ──► Recipient inbox
         │                       └── temp msmtp conf (deleted after send)
         │
         ├─[5]─► Monitoring.sh ──► SSH ──► Remote commands
         │                                    └──► local .txt ──► PDF
         │
         └─[6]─► Automation.sh
                     ├── ping 8.8.8.8 (connectivity check)
                     ├── Report.sh (generate PDFs)
                     ├── msmtp (send email)
                     └── automation_send.log (timestamped log)
```

### Remote Monitoring Flow

```
Monitoring.sh
     │
     ├── Input: N remote machines (IP, user, password)
     │
     ├── For each machine:
     │     sshpass → SSH → Remote audit commands
     │         └── stdout → local temp .txt file
     │                   └── enscript → PostScript
     │                               └── ps2pdf → <IP>_<timestamp>.pdf
     │                                           └── temp .txt deleted
     │
     └── SUMMARY_<timestamp>.pdf (consolidated)
```

---

## 19. Output Files Reference

| File | Location | Generated By | Description |
|------|----------|-------------|-------------|
| `full_report.pdf` | `~/Desktop/system_report/` | `Report.sh` | Complete hardware + software audit, 6 sections |
| `short_report.pdf` | `~/Desktop/system_report/` | `Report.sh` | Executive summary for quick review |
| `automation_send.log` | `~/Desktop/system_report/` | `Automation.sh` | Timestamped pipeline execution log |
| `<IP>_<timestamp>.pdf` | `~/reports/remote/` | `Monitoring.sh` | Per-machine remote audit PDF |
| `SUMMARY_<timestamp>.pdf` | `~/reports/remote/` | `Monitoring.sh` | Consolidated session summary across all remote hosts |
| `remote_monitor.log` | `~/reports/` | `Monitoring.sh` | SSH monitoring session log |
| `/tmp/.msmtp_tmp.conf` | `/tmp/` | `Send.sh`, `Automation.sh` | Temporary msmtp config (deleted immediately after use) |
| `/tmp/msmtp.log` | `/tmp/` | msmtp | msmtp delivery log (useful for debugging) |

---

## 20. Environment Variables & Secrets Management

Hardcoding credentials directly in `Automation.sh` is convenient but not ideal. Here are safer alternatives:

### Option A: Shell Environment Variables

Add to `/etc/environment` or your shell profile (`~/.bashrc`, `/root/.bashrc`):

```bash
export AUDIT_GMAIL="your@gmail.com"
export AUDIT_PASS="abcd efgh ijkl mnop"
export AUDIT_RECIPIENT="admin@company.com"
```

Then in `Automation.sh`, replace hardcoded values:

```bash
SENDER_GMAIL="${AUDIT_GMAIL}"
SENDER_PASS="${AUDIT_PASS}"
RECIPIENT_EMAIL="${AUDIT_RECIPIENT}"
```

### Option B: Separate Credentials File

Create a protected credentials file:

```bash
# Create the file
sudo nano /etc/audit-toolkit/credentials

# Contents:
SENDER_GMAIL="your@gmail.com"
SENDER_PASS="abcd efgh ijkl mnop"
RECIPIENT_EMAIL="admin@company.com"
```

```bash
# Restrict permissions
sudo chmod 600 /etc/audit-toolkit/credentials
sudo chown root:root /etc/audit-toolkit/credentials
```

Then source it at the top of `Automation.sh`:

```bash
source /etc/audit-toolkit/credentials
```

### Option C: Pass (UNIX Password Manager)

If `pass` is installed:

```bash
# Store credentials
pass insert audit/gmail
pass insert audit/app-password

# Retrieve in script
SENDER_GMAIL=$(pass audit/gmail)
SENDER_PASS=$(pass audit/app-password)
```

---

## 21. Extending the Toolkit

The toolkit's modular design makes it straightforward to add new audit capabilities.

### Adding a New Audit Script

1. Create your script in the same directory as `Launcher.sh`:

```bash
nano ~/Desktop/OS_Project/MyAudit.sh
chmod +x MyAudit.sh
```

2. Add a new menu option in `Launcher.sh`:

```bash
echo "[7] My Custom Audit"
# ...
7) bash "$SCRIPT_DIR/MyAudit.sh" ;;
```

### Adding a New Report Section

In `Report.sh`, follow the existing pattern:

```bash
echo "=============================" >> "$REPORT_TXT"
echo "  MY CUSTOM SECTION"          >> "$REPORT_TXT"
echo "=============================" >> "$REPORT_TXT"
echo "Custom data: $(my-command)"   >> "$REPORT_TXT"
```

### Adapting for RPM-Based Systems

Replace `dpkg`-based commands with their RPM equivalents:

| Debian/Ubuntu | RHEL/Fedora |
|---------------|-------------|
| `dpkg -l \| wc -l` | `rpm -qa \| wc -l` |
| `apt list --installed` | `dnf list installed` |
| `apt install <pkg>` | `dnf install <pkg>` |
| `/etc/apt/sources.list` | `/etc/yum.repos.d/` |

### Supporting Non-Gmail SMTP

Modify the msmtp config section in `Send.sh`:

```bash
# For Outlook / Office 365:
host smtp.office365.com
port 587

# For self-hosted / custom SMTP:
host your.smtp.server
port 587
auth on
tls on
```

---

## 22. FAQ

**Q: Do I need root to run all scripts?**  
A: Most scripts (`Hardware.sh`, `Software.sh`, `Report.sh`, `Send.sh`, `Automation.sh`) require root for full functionality. `Monitoring.sh` does not require local root, but may need root on the remote host for complete hardware data.

**Q: Can I run the scripts without the TUI launcher?**  
A: Yes. Every script can be executed directly: `sudo bash Hardware.sh`, `sudo bash Report.sh`, etc.

**Q: The PDFs are owned by root. How do I fix this?**  
A: `Report.sh` attempts to automatically `chown` PDFs to the real invoking user. If this fails, manually change ownership: `sudo chown $USER ~/Desktop/system_report/*.pdf`

**Q: Can I use a non-Gmail email provider?**  
A: Yes, but you'll need to modify the msmtp configuration in `Send.sh` and `Automation.sh` to use your provider's SMTP host, port, and authentication method. See [Section 20](#20-extending-the-toolkit).

**Q: How do I monitor remote machines without storing their passwords?**  
A: Set up SSH key-based authentication. See [Section 11.4](#114-security-warning) for instructions. Then remove the `sshpass` dependency and use standard `ssh` commands in `Monitoring.sh`.

**Q: Can I run this in a Docker container or VM?**  
A: Yes, with limitations. Some hardware commands (`dmidecode`, `lspci`) may return empty results in virtualised environments. The toolkit will still function but hardware sections may be incomplete.

**Q: How large are the generated PDFs?**  
A: Typically 50–200 KB for `full_report.pdf` and 20–80 KB for `short_report.pdf`, depending on the number of services, packages, and processes on the system.

**Q: Is there a way to view reports without downloading them?**  
A: `Report.sh` automatically opens the output folder after generation using `xdg-open`. If you're on a headless server, use `scp` to copy PDFs to a local machine.

**Q: My cron job doesn't send email. What should I check?**  
A: (1) Verify absolute paths in the crontab. (2) Check `/var/log/audit_cron.log` for error output. (3) Ensure `msmtp` is installed and credentials are configured. (4) Test `Automation.sh` manually first.

---

## 23. Glossary

| Term | Definition |
|------|-----------|
| **ANSI color codes** | Escape sequences embedded in terminal output to produce colored text. Stripped during PDF conversion. |
| **App Password** | A 16-character token generated by Google to allow third-party apps to send email via Gmail SMTP without using your main account password. |
| **cron** | A Unix time-based job scheduler. Runs commands at specified intervals as defined in a crontab file. |
| **crontab** | The configuration file for cron. Contains one job per line in `minute hour day month weekday command` format. |
| **dmidecode** | A tool that reads hardware information from the system's Desktop Management Interface (DMI) tables, including RAM slots, CPU sockets, and motherboard details. |
| **enscript** | A command-line tool that converts plain text files to PostScript format for further processing (e.g., conversion to PDF). |
| **ghostscript** | An interpreter for PostScript and PDF. The `ps2pdf` command (used in this toolkit) is part of the ghostscript package. |
| **lshw** | "List Hardware" — a tool that provides a detailed description of the hardware configuration of a machine. |
| **MIME** | Multipurpose Internet Mail Extensions — a standard for encoding email attachments (e.g., PDF files) in binary format for transmission. |
| **msmtp** | A lightweight SMTP client used by this toolkit to send email from the command line without a full mail server. |
| **nmcli** | NetworkManager command-line interface — used to query Wi-Fi SSID, interface status, and connection details. |
| **PostScript** | A page description language used as an intermediate format in the PDF generation pipeline (text → PostScript → PDF). |
| **SMART** | Self-Monitoring, Analysis, and Reporting Technology — a disk health monitoring system built into most modern hard drives and SSDs. |
| **SMTP** | Simple Mail Transfer Protocol — the standard protocol for sending email. Gmail uses port 587 with STARTTLS. |
| **sshpass** | A utility for providing SSH passwords non-interactively in shell scripts (instead of requiring keyboard input). |
| **STARTTLS** | An email protocol command that upgrades an existing insecure connection to a secure TLS-encrypted connection. Used on port 587. |
| **TUI** | Text User Interface — a full-screen interactive menu displayed in a terminal, as opposed to a graphical (GUI) interface. |
| **upower** | UPower — a daemon that provides power management information, including battery status, to applications. |

---

---

> ⚠️ **Disclaimer:** This toolkit is intended for authorized use on systems you own or have explicit permission to audit. Unauthorized use of remote monitoring features (`Monitoring.sh`) against systems without permission may violate computer access laws. Always obtain proper authorization before auditing any machine you do not own.

---

<div align="center">

*Built with 🛠️ Bash · Designed for Linux ·

</div>
