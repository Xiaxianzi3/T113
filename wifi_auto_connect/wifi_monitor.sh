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
