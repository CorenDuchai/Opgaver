#!/bin/bash

LOG="/var/log/system-monitor.log"

DISK_THRESHOLD=85
RAM_THRESHOLD=90

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

CPU=$(vmstat 1 2 | tail -1 | awk '{print 100 - $15}')
RAM=$(free | awk '/Mem:/ {printf "%.1f", $3/$2 * 100}')
DISK=$(df -P / | awk 'NR==2 {gsub("%","",$5); print $5}')

echo "$TIMESTAMP CPU=${CPU}% RAM=${RAM}% DISK=${DISK}%" >> "$LOG"

if (( DISK > DISK_THRESHOLD )); then
    echo "$TIMESTAMP WARNING: Disk usage is ${DISK}% - threshold is ${DISK_THRESHOLD}%" >> "$LOG"
fi

if awk "BEGIN {exit !($RAM > $RAM_THRESHOLD)}"; then
    echo "$TIMESTAMP WARNING: RAM usage is ${RAM}% - threshold is ${RAM_THRESHOLD}%" >> "$LOG"
fi
