# Step-by-step guide to debug and fix the monitoring script, service, and timer

# 1. Refine the bash script for better debugging
# Save this content to /usr/local/bin/monitor_test.sh
cat << 'EOF' > /usr/local/bin/monitor_test.sh
#!/bin/bash

# Log file location
LOG_FILE="/var/log/monitoring.log"

# URL for monitoring API
MONITORING_URL="https://test.com/monitoring/test/api"

# PID file for tracking process
PID_FILE="/var/run/test_monitor.pid"

# Function to log messages with timestamp
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE" 2>/dev/null || echo "ERROR: Failed to write to $LOG_FILE" >&2
}

# Log script start for debugging
log_message "Script started"

# Check if curl is installed
if ! command -v curl >/dev/null 2>&1; then
    log_message "Error: curl is not installed"
    exit 1
fi

# Ensure log file is writable
if [ ! -w "$LOG_FILE" ]; then
    log_message "Error: Log file $LOG_FILE is not writable"
    exit 1
fi

# Ensure PID file directory exists and is writable
PID_DIR=$(dirname "$PID_FILE")
if [ ! -w "$PID_DIR" ]; then
    log_message "Error: PID directory $PID_DIR is not writable"
    exit 1
fi

# Get the current PID of the 'test' process
CURRENT_PID=$(pgrep -x test)

# Store the previous PID
PREVIOUS_PID=""
if [ -f "$PID_FILE" ] && [ -r "$PID_FILE" ]; then
    PREVIOUS_PID=$(cat "$PID_FILE")
    log_message "Previous PID read: $PREVIOUS_PID"
fi

# Check if the process is running
if [ -n "$CURRENT_PID" ]; then
    log_message "Process 'test' is running with PID: $CURRENT_PID"
    # Process is running, attempt to contact monitoring API
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$MONITORING_URL" --max-time 10)
    
    # Check if the API is unreachable (non-200 status code or timeout)
    if [ "$RESPONSE" != "200" ]; then
        log_message "Monitoring server unavailable. HTTP response code: $RESPONSE"
    else
        log_message "Monitoring server contacted successfully. HTTP response code: $RESPONSE"
    fi
    
    # Check if the process was restarted (PID changed)
    if [ -n "$PREVIOUS_PID" ] && [ "$PREVIOUS_PID" != "$CURRENT_PID" ]; then
        log_message "Process 'test' restarted. Previous PID: $PREVIOUS_PID, New PID: $CURRENT_PID"
    fi
    
    # Update the stored PID
    echo "$CURRENT_PID" > "$PID_FILE" 2>/dev/null || log_message "Error: Failed to write PID to $PID_FILE"
else
    log_message "Process 'test' is not running"
fi

# Log script completion
log_message "Script completed"
EOF

# 2. Make the script executable
chmod +x /usr/local/bin/monitor_test.sh

# 3. Create the systemd service file
# Save this content to /etc/systemd/system/test-monitor.service
cat << 'EOF' > /etc/systemd/system/test-monitor.service
[Unit]
Description=Test Process Monitoring Service
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash /usr/local/bin/monitor_test.sh
RemainAfterExit=no

[Install]
WantedBy=multi-user.target
EOF

# 4. Create the systemd timer file
# Save this content to /etc/systemd/system/test-monitor.timer
cat << 'EOF' > /etc/systemd/system/test-monitor.timer
[Unit]
Description=Timer for Test Process Monitoring
Requires=test-monitor.service

[Timer]
OnBootSec=60
OnUnitActiveSec=60
Unit=test-monitor.service
Persistent=true

[Install]
WantedBy=timers.target
EOF

# 5. Set up file permissions
# Create and set permissions for the log file
touch /var/log/monitoring.log
chown root:root /var/log/monitoring.log
chmod 664 /var/log/monitoring.log

# Ensure /var/run is writable for PID file
touch /var/run/test_monitor.pid
chown root:root /var/run/test_monitor.pid
chmod 664 /var/run/test_monitor.pid

# 6. Stop any running instances
systemctl stop test-monitor.timer
systemctl stop test-monitor.service

# 7. Reload systemd to recognize changes
systemctl daemon-reload

# 8. Reset failed state to clear any previous errors
systemctl reset-failed test-monitor.timer
systemctl reset-failed test-monitor.service

# 9. Enable both the service and timer to start on boot
systemctl enable test-monitor.service
systemctl enable test-monitor.timer

# 10. Start the timer to begin monitoring
systemctl start test-monitor.timer

# 11. Verify the status
# Check if the timer is active and running
systemctl status test-monitor.timer
# Check if the service runs correctly
systemctl status test-monitor.service

# 12. Test and troubleshoot
# Run the script manually to check for errors
/bin/bash /usr/local/bin/monitor_test.sh
# Check the log file for entries
cat /var/log/monitoring.log
# Check for script errors in stderr
/bin/bash /usr/local/bin/monitor_test.sh 2> /tmp/monitor_test_errors.log
cat /tmp/monitor_test_errors.log

# Notes:
# - Ensure curl is installed: sudo apt-get install curl (on Debian/Ubuntu) or sudo yum install curl (on CentOS/RHEL)
# - The script runs every minute via the timer
# - Added debug logging for script start, completion, PID reads, and process status
# - Logs are written to /var/log/monitoring.log for all actions
# - Changed permissions to 664 for better access (adjust if needed)
# - If no logs appear, check /tmp/monitor_test_errors.log for errors
# - Ensure the 'test' process exists; start it manually if needed for testing
