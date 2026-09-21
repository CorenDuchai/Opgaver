#!/bin/bash

set -euo pipefail

DISK_THRESHOLD=85
ROOT_MOUNT="/"

print_header() {
    echo "========================================"
    echo " Linux 101 - System Health Check"
    echo " Host: $(hostname)"
    echo " Time: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "========================================"
}

check_firewall() {
    echo
    echo "--- Firewall status ---"

    if command -v ufw >/dev/null 2>&1; then
        ufw status verbose
    else
        echo "[WARNING] UFW is not installed."
    fi
}

check_disk() {
    echo
    echo "--- Disk usage ---"

    local disk_used
    local disk_free

    disk_used=$(df -P "$ROOT_MOUNT" | awk 'NR==2 {gsub("%","",$5); print $5}')
    disk_free=$(df -hP "$ROOT_MOUNT" | awk 'NR==2 {print $4}')

    echo "Free space on $ROOT_MOUNT: $disk_free"
    echo "Disk usage: ${disk_used}%"

    if (( disk_used > DISK_THRESHOLD )); then
        echo "[WARNING] Disk usage is above ${DISK_THRESHOLD}%."
    else
        echo "[OK] Disk usage is below ${DISK_THRESHOLD}%."
    fi
}

check_users() {
    echo
    echo "--- Logged-in users ---"

    local logged_in
    logged_in=$(w -h)

    if [[ -z "$logged_in" ]]; then
        echo "No users currently logged in."
    else
        echo "$logged_in"
    fi
}

check_uid0() {
    echo
    echo "--- UID 0 accounts ---"

    local extra_uid0
    extra_uid0=$(awk -F: '$3 == 0 && $1 != "root" {print $1}' /etc/passwd)

    if [[ -z "$extra_uid0" ]]; then
        echo "[OK] Only root has UID 0."
    else
        echo "[WARNING] Additional UID 0 accounts found:"
        echo "$extra_uid0"
    fi
}

main() {
    if [[ "$EUID" -ne 0 ]]; then
        echo "Run this script with sudo:"
        echo "sudo $0"
        exit 1
    fi

    print_header
    check_firewall
    check_disk
    check_users
    check_uid0
}

main
