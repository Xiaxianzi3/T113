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
