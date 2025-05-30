#!/bin/bash

LOG_FILE="/var/log/monitoring.log"

MONITORING_URL="https://test.com/monitoring/test/api"

PID_FILE="/var/run/test_monitor.pid"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE" 2>/dev/null || echo "ERROR: Failed to write to $LOG_FILE" >&2
}

log_message "Script started"

if ! command -v curl >/dev/null 2>&1; then
    log_message "Error: curl is not installed"
    exit 1
fi

if [ ! -w "$LOG_FILE" ]; then
    log_message "Error: Log file $LOG_FILE is not writable"
    exit 1
fi

PID_DIR=$(dirname "$PID_FILE")
if [ ! -w "$PID_DIR" ]; then
    log_message "Error: PID directory $PID_DIR is not writable"
    exit 1
fi

CURRENT_PID=$(pgrep -x test)

PREVIOUS_PID=""
if [ -f "$PID_FILE" ] && [ -r "$PID_FILE" ]; then
    PREVIOUS_PID=$(cat "$PID_FILE")
    log_message "Previous PID read: $PREVIOUS_PID"
fi

if [ -n "$CURRENT_PID" ]; then
    log_message "Process 'test' is running with PID: $CURRENT_PID"
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$MONITORING_URL" --max-time 10)
    
    if [ "$RESPONSE" != "200" ]; then
        log_message "Monitoring server unavailable. HTTP response code: $RESPONSE"
    else
        log_message "Monitoring server contacted successfully. HTTP response code: $RESPONSE"
    fi
    
    if [ -n "$PREVIOUS_PID" ] && [ "$PREVIOUS_PID" != "$CURRENT_PID" ]; then
        log_message "Process 'test' restarted. Previous PID: $PREVIOUS_PID, New PID: $CURRENT_PID"
    fi
    
    echo "$CURRENT_PID" > "$PID_FILE" 2>/dev/null || log_message "Error: Failed to write PID to $PID_FILE"
else
    log_message "Process 'test' is not running"
fi

log_message "Script completed"
