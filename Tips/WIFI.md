# 开机后台扫描并连接WIFI，支持掉线重连

## 1. 配置WIFI网络名+密码
```
vim /etc/wpa_supplicant.conf
```
```
ctrl_interface=/var/lock/wpa_supplicant
ctrl_interface_group=0
ap_scan=1
network={
    ssid="wifi_name1" 
    scan_ssid=1
    key_mgmt=WPA-EAP WPA-PSK IEEE8021X NONE
    psk="your password" 
    priority=5
}

network={
    ssid="wifi_name2"
    scan_ssid=1
    key_mgmt=WPA-EAP WPA-PSK IEEE8021X NONE
    psk="your password"
    priority=4
}
```


## 2. 创建主连接脚本（带重连功能）
```
vim /usr/bin/wifi_connect.sh
```
```bash
#!/bin/sh

# WiFi自动连接脚本（带掉线重连）
LOG_FILE="/tmp/wifi_connect.log"

# 确保/tmp目录存在
mkdir -p /tmp

# 记录日志函数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# 检查是否已连接的函数
is_connected() {
    # 检查是否有IP地址
    if ifconfig wlan0 2>/dev/null | grep -q "inet addr"; then
        return 0 # 已连接
    else
        return 1 # 未连接
    fi
}

# 主连接函数
connect_wifi() {
    log "=== Starting WiFi connection attempt ==="
    
    # 停止可能存在的进程
    killall wpa_supplicant 2>/dev/null
    killall udhcpc 2>/dev/null
    sleep 1
    
    # 启用无线网卡
    log "Bringing up wlan0 interface..."
    ifconfig wlan0 up
    sleep 2
    
    # 启动wpa_supplicant
    log "Starting wpa_supplicant..."
    wpa_supplicant -D wext -c /etc/wpa_supplicant.conf -i wlan0 -B
    if [ $? -ne 0 ]; then
        log "ERROR: Failed to start wpa_supplicant"
        return 1
    fi
    
    # 等待认证
    log "Waiting for authentication..."
    sleep 8
    
    # 获取IP地址
    log "Requesting IP address..."
    udhcpc -i wlan0 -n -q -t 5
    
    # 检查是否连接成功
    if is_connected; then
        IP_ADDRESS=$(ifconfig wlan0 | grep "inet addr" | awk '{print $2}' | cut -d: -f2)
        log "Success! Connected with IP: $IP_ADDRESS"
        return 0
    else
        log "WARNING: Connection attempt failed"
        return 1
    fi
}

# 执行连接
connect_wifi

log "=== WiFi connection process finished ==="
```
```
chmod +x /usr/bin/wifi_connect.sh
```


## 3. 掉线监控脚本
```shell
vim /usr/bin/wifi_monitor.sh
```
```bash
#!/bin/sh

# WiFi掉线监控和自动重连脚本
LOG_FILE="/tmp/wifi_monitor.log"

# 记录日志函数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# 检查连接状态的函数
check_connection() {
    # 方法1: 检查IP地址
    if ! ifconfig wlan0 2>/dev/null | grep -q "inet addr"; then
        log "No IP address - connection lost"
        return 1
    fi
    
    # 方法2: 检查wpa_supplicant进程
    if ! ps | grep -q "[w]pa_supplicant.*wlan0"; then
        log "wpa_supplicant process not found"
        return 1
    fi
    
    # 方法3: 可选的心跳检测（ping网关或DNS）
    # 先获取网关地址
    GATEWAY=$(route -n | grep 'wlan0' | grep 'UG' | awk '{print $2}' | head -1)
    if [ -n "$GATEWAY" ]; then
        if ! ping -c 2 -W 3 -I wlan0 $GATEWAY >/dev/null 2>&1; then
            log "Cannot ping gateway $GATEWAY - connection issue"
            return 1
        fi
    else
        # 如果没有网关，尝试ping公共DNS
        if ! ping -c 2 -W 3 -I wlan0 8.8.8.8 >/dev/null 2>&1; then
            log "Cannot ping external host - connection issue"
            return 1
        fi
    fi
    
    return 0 # 连接正常
}

log "=== Starting WiFi connection monitor ==="
log "Monitor PID: $$"

# 监控循环
while true; do
    if ! check_connection; then
        log "Connection lost! Attempting to reconnect..."
        
        # 等待一段时间再重试，避免频繁重连
        sleep 10
        
        # 执行重连
        /usr/bin/wifi_connect.sh >> "$LOG_FILE" 2>&1
        
        # 给系统一些时间恢复
        sleep 20
    else
        # 连接正常，记录一次心跳（可选）
        if [ $(date +%M) == "00" ]; then # 每小时记录一次心跳
            log "Connection status: OK"
        fi
    fi
    
    # 检查间隔
    sleep 30
done
```
```
chmod +x /usr/bin/wifi_monitor.sh
```


## 4. 开机自启动脚本
```
vim /etc/init.d/S99wifi_connect
```
```bash
#!/bin/sh

# WiFi自动连接启动脚本（包含监控）

case "$1" in
    start)
        echo "Starting WiFi connection and monitor..."
        # 启动连接脚本
        /usr/bin/wifi_connect.sh > /tmp/wifi_start.log 2>&1 &
        
        # 等待连接完成
        sleep 15
        
        # 启动监控脚本
        /usr/bin/wifi_monitor.sh > /tmp/wifi_monitor_start.log 2>&1 &
        ;;
        
    stop)
        echo "Stopping WiFi connection and monitor..."
        # 停止监控脚本
        killall wifi_monitor.sh 2>/dev/null
        
        # 停止连接进程
        killall wpa_supplicant 2>/dev/null
        killall udhcpc 2>/dev/null
        ifconfig wlan0 down 2>/dev/null
        
        # 确保所有相关进程都停止
        sleep 2
        ;;
        
    restart)
        echo "Restarting WiFi connection..."
        $0 stop
        sleep 5
        $0 start
        ;;
        
    status)
        echo "=== WiFi Connection Status ==="
        echo "Monitor process: $(ps | grep '[w]ifi_monitor.sh' | wc -l) running"
        echo "wpa_supplicant: $(ps | grep '[w]pa_supplicant' | wc -l) running"
        echo "udhcpc: $(ps | grep '[u]dhcpc' | wc -l) running"
        echo ""
        echo "Interface status:"
        ifconfig wlan0 2>/dev/null | grep -E "(inet addr|UP)"
        echo ""
        echo "Connection status:"
        iwconfig wlan0 2>/dev/null | grep "ESSID"
        ;;
        
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac

exit 0
```
```
chmod +x /etc/init.d/S99wifi_connect
```