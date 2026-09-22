#!/bin/bash

timestamp=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="$HOME/server_monitor.log"

status=0
send_alert() {
    echo "ALERT: $1" | tee -a "$LOG_FILE"
}
echo "===== Server Health Check ====="
echo "Check time: $timestamp" | tee -a "$LOG_FILE"
echo

if systemctl is-active --quiet nginx; then
    echo "Nginx: RUNNING" | tee -a "$LOG_FILE"
else
    echo "Nginx: NOT RUNNING" | tee -a "$LOG_FILE"
    send_alert "Nginx is not running"
    status=1
fi

echo

disk=$(df / | awk 'NR==2 {gsub("%","",$5);print $5}')
echo "Disk usage: ${disk}%" | tee -a "$LOG_FILE"

if [ "$disk" -ge 80 ]; then
    echo "Disk: HIGH USAGE" | tee -a "$LOG_FILE"
send_alert "Disk usage is ${disk}%"
    status=1
else
    echo "Disk: OK" | tee -a "$LOG_FILE"
fi

echo

memory=$(free -h | awk '/Mem:/ {print $3 "/" $2}')
memory_percent=$(free | awk '/Mem:/ {printf "%.0f", ($3/$2)*100}')
echo "Memory usage: $memory" | tee -a "$LOG_FILE"
if [ "$memory_percent" -ge 80 ]; then
    echo "Memory: HIGH USAGE (${memory_percent}%)" | tee -a "$LOG_FILE"
    send_alert "Memory usage is ${memory_percent}%"
    status=1
else
    echo "Memory: OK (${memory_percent}%)" | tee -a "$LOG_FILE"
fi
echo

cpu=$(top -bn1 | awk -F',' '/Cpu\(s\)/ {
    for (i=1; i<=NF; i++) {
        if ($i ~ / id/) {
            gsub(/[^0-9.]/, "", $i)
            print 100 - $i
            exit
        }
    }
}')

echo "CPU usage: ${cpu}%" | tee -a "$LOG_FILE"

if awk "BEGIN {exit !($cpu >= 80)}"; then
    echo "CPU: HIGH USAGE" | tee -a "$LOG_FILE"
send_alert "CPU usage is ${cpu}%"
    status=1
else
    echo "CPU: OK" | tee -a "$LOG_FILE"
fi

echo

echo "===== Health Summary =====" | tee -a "$LOG_FILE"
echo "Nginx, disk, memory and CPU checks completed." | tee -a "$LOG_FILE"
echo

if [ $status -eq 0 ]; then
    echo "Overall status: HEALTHY" | tee -a "$LOG_FILE"
else
    echo "Overall status: CHECK REQUIRED" | tee -a "$LOG_FILE"
fi

exit $status
