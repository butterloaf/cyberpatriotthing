#!/bin/bash
#make sure to run with sudo and do chmod +x before running

LOG="$(dirname "$0")/CyberPatriot_Debian_Log.txt"

if [ "$EUID" -ne 0 ]; then
    echo "Run this with sudo or this won't work"
    exit 1
fi

confirm() {
    echo
    read -r -p "$1 [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

log_result() {
    if [ "$1" -eq 0 ]; then
        echo "[$(date)] SUCCESS: $2" >> "$LOG"
        echo "Change completed."
    else
        echo "[$(date)] FAILED: $2" >> "$LOG"
        echo "Command failed. Check the system."
    fi
}

pause() {
    echo
    read -r -p "Press Enter to continue..."
}

users() {
    clear
    echo "User Accounts"

    echo
    echo "All users:"
    cut -d: -f1,3,7 /etc/passwd

    echo
    echo "UID 0 accounts:"
    awk -F: '$3 == 0 {print $1}' /etc/passwd

    echo
    echo "Sudo group:"
    getent group sudo

    echo
    echo "Review unfamiliar accounts manually."
    pause
}

passwords() {
    clear
    echo "Password Policies"

    echo
    echo "Password aging defaults:"
    grep -E '^(PASS_MAX_DAYS|PASS_MIN_DAYS|PASS_WARN_AGE)' \
        /etc/login.defs

    echo
    echo "Password PAM configuration:"
    grep -hE 'pam_pwquality|pam_pwhistory|pam_unix' \
        /etc/pam.d/common-password 2>/dev/null

    echo
    echo "Password expiration information:"
    chage -l root

    echo
    echo "Compare settings with the competition README."
    pause
}

firewall() {
    clear
    echo "Firewall"

    if command -v ufw >/dev/null 2>&1; then
        ufw status verbose
    fi

    if command -v nft >/dev/null 2>&1; then
        echo
        echo "NFTables rules:"
        nft list ruleset
    fi

    if command -v iptables >/dev/null 2>&1; then
        echo
        echo "IPTables rules:"
        iptables -L -n
    fi

    echo
    echo "Do not enable a firewall without checking existing rules."
    echo "Incorrect rules can interrupt network access."
    pause
}

ssh_check() {
    clear
    echo "Ssh Security"

    if command -v sshd >/dev/null 2>&1; then
        sshd -T 2>/dev/null | grep -E \
            'permitrootlogin|passwordauthentication|pubkeyauthentication'
    else
        echo "OpenSSH server is not installed."
    fi

    echo
    echo "SSH service status:"
    systemctl status ssh --no-pager 2>/dev/null ||
        echo "SSH service is not running or not installed."

    echo
    echo "SSH configuration:"
    if [ -f /etc/ssh/sshd_config ]; then
        grep -vE '^[[:space:]]*#|^[[:space:]]*$' \
            /etc/ssh/sshd_config
    fi

    echo
    echo "Review SSH settings against the README."
    pause
}

shares() {
    clear
    echo "Network Shares"

    if command -v smbstatus >/dev/null 2>&1; then
        smbstatus
    else
        echo "Samba is not installed."
    fi

    echo
    echo "NFS exports:"
    if [ -f /etc/exports ]; then
        cat /etc/exports
    else
        echo "No NFS exports file found."
    fi

    pause
}

services() {
    clear
    echo "Running Services"

    systemctl list-units \
        --type=service \
        --state=running \
        --no-pager

    echo
    echo "Enabled services:"
    systemctl list-unit-files \
        --type=service \
        --state=enabled \
        --no-pager

    echo
    echo "Do not disable unfamiliar services without checking."
    pause
}

auditing() {
    clear
    echo "Security Auditing"

    if command -v auditctl >/dev/null 2>&1; then
        auditctl -s
    else
        echo "Audit tools are not installed."
    fi

    echo
    systemctl status auditd --no-pager 2>/dev/null ||
        echo "Auditd is not running or not installed."

    pause
}

software() {
    clear
    echo "Installed Software"

    dpkg-query -W \
        -f='${binary:Package} ${Version}\n' 2>/dev/null

    pause
}

updates() {
    clear
    echo "Available Updates"

    echo "Checking package information..."
    apt list --upgradable 2>/dev/null

    echo
    echo "Recently installed packages:"
    grep -h " install " /var/log/dpkg.log 2>/dev/null |
        tail -20

    echo
    echo "Review updates before installing anything."
    pause
}

system_info() {
    clear
    echo "System Information"

    echo
    cat /etc/os-release

    echo
    echo "Kernel:"
    uname -r

    echo
    echo "Hostname:"
    hostnamectl

    echo
    echo "Disk space:"
    df -h

    echo
    echo "Network interfaces:"
    ip -brief address

    echo
    echo "Listening ports:"
    ss -tulpn

    pause
}

while true; do
    clear
    echo "Computer: $(hostname)"
    echo "User: ${SUDO_USER:-root}"
    echo
    echo "[1] User accounts"
    echo "[2] Password policies"
    echo "[3] Firewall"
    echo "[4] SSH security"
    echo "[5] Network shares"
    echo "[6] Services"
    echo "[7] Security auditing"
    echo "[8] Installed software"
    echo "[9] Updates"
    echo "[10] System information"
    echo "[0] Exit"
    echo
    read -r -p "Choose an option: " choice

    case "$choice" in
        1) users ;;
        2) passwords ;;
        3) firewall ;;
        4) ssh_check ;;
        5) shares ;;
        6) services ;;
        7) auditing ;;
        8) software ;;
        9) updates ;;
        10) system_info ;;
        0)
            echo "Log: $LOG"
            exit 0
            ;;
        *)
            echo "Invalid option."
            pause
            ;;
    esac
done
