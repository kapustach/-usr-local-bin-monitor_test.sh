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

### Автозапуск

```bash
systemctl enable test-monitor.service
systemctl enable test-monitor.timer
```

### Запуск таймера

```bash
systemctl start test-monitor.timer
```

### Проверка статуса

```bash
systemctl status test-monitor.timer
systemctl status test-monitor.service
```

### Запуск скрипта и проверка файла с логами

```bash
/bin/bash /usr/local/bin/monitor_test.sh
cat /var/log/monitoring.log
```
