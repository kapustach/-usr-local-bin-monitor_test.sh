### Создание файла для логов 

```bash
touch /var/log/monitoring.log
chown root:root /var/log/monitoring.log
chmod 664 /var/log/monitoring.log
```

### Остановка сервисов если они запущены 

```bash
systemctl stop test-monitor.timer
systemctl stop test-monitor.service
```

### Перезапуск всех демонов

```bash
systemctl daemon-reload
```

```bash
# 8. Reset failed state to clear any previous errors
systemctl reset-failed test-monitor.timer
systemctl reset-failed test-monitor.service
```

```bash
# 9. Enable both the service and timer to start on boot
systemctl enable test-monitor.service
systemctl enable test-monitor.timer
```

```bash
# 10. Start the timer to begin monitoring
systemctl start test-monitor.timer
```

```bash
# 11. Verify the status
# Check if the timer is active and running
systemctl status test-monitor.timer
# Check if the service runs correctly
systemctl status test-monitor.service
```

# 12. Test and troubleshoot

# Run the script manually to check for errors

```bash
/bin/bash /usr/local/bin/monitor_test.sh
# Check the log file for entries
cat /var/log/monitoring.log
# Check for script errors in stderr
/bin/bash /usr/local/bin/monitor_test.sh 2> /tmp/monitor_test_errors.log
cat /tmp/monitor_test_errors.log
```
