#!/bin/bash

# 启用严格错误处理
set -euo pipefail

# 配置日志文件
LOG_FILE="/var/log/enable_bbr.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# 日志记录函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1: $2"
}

# 检查当前拥塞控制算法
check_current_algorithm() {
    log "INFO" "检查当前TCP拥塞控制算法"
    local current_algorithm
    if current_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null); then
        log "INFO" "当前拥塞控制算法: $current_algorithm"
        if [ "$current_algorithm" = "bbr" ]; then
            log "INFO" "BBR已启用，无需进一步操作"
            return 0
        else
            log "INFO" "当前算法不是BBR，需要启用"
            return 1
        fi
    else
        log "WARNING" "无法获取当前拥塞控制算法状态"
        return 2
    fi
}

# 检查内核版本兼容性
check_kernel_version() {
    log "INFO" "检查内核版本兼容性"
    local kernel_version
    kernel_version=$(uname -r | awk -F. '{print $1 * 1000+$2}')
    
    if [ "$kernel_version" -lt 4009 ]; then
        log "ERROR" "内核版本低于4.9，不支持BBR"
        exit 1
    else
        log "INFO" "内核版本符合要求: $(uname -r)"
    fi
}

# 检查BBR模块可用性
check_bbr_module() {
    log "INFO" "检查BBR模块可用性"
    if ! sudo modprobe tcp_bbr; then
        log "ERROR" "无法加载tcp_bbr模块"
        exit 1
    fi
    
    # 将模块加入自动加载
    if ! grep -q "tcp_bbr" /etc/modules-load.d/modules.conf 2>/dev/null; then
        echo "tcp_bbr" | sudo tee -a /etc/modules-load.d/modules.conf >/dev/null
        log "INFO" "已将tcp_bbr添加到自动加载模块"
    fi
}

# 启用BBR算法
enable_bbr() {
    log "INFO" "开始配置BBR"
    
    # 配置队列规则
    if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
        echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf >/dev/null
        log "INFO" "已配置fq队列规则"
    fi
    
    # 配置BBR拥塞控制
    if ! grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf; then
        echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf >/dev/null
        log "INFO" "已配置BBR拥塞控制"
    fi
    
    # 应用配置
    if sudo sysctl -p; then
        log "INFO" "成功应用sysctl配置"
    else
        log "ERROR" "应用sysctl配置失败"
        exit 1
    fi
}

# 验证BBR启用状态
verify_bbr() {
    log "INFO" "开始验证BBR启用状态"
    sleep 2  # 等待配置生效
    
    local final_algorithm
    final_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
    
    if [ "$final_algorithm" = "bbr" ]; then
        log "SUCCESS" "BBR启用验证成功"
        echo "=================================================="
        echo "BBR拥塞控制算法已成功启用"
        echo "当前算法: $final_algorithm"
        echo "可用算法: $(sysctl -n net.ipv4.tcp_available_congestion_control)"
        echo "模块状态: $(lsmod | grep tcp_bbr || echo "未找到模块")"
        echo "=================================================="
    else
        log "ERROR" "BBR启用验证失败，当前算法: $final_algorithm"
        exit 1
    fi
}

# 主执行函数
main() {
    log "INFO" "=== 开始BBR启用脚本 ==="
    
    # 检查是否已启用
    if check_current_algorithm; then
        exit 0
    fi
    
    # 执行启用流程
    check_kernel_version
    check_bbr_module
    enable_bbr
    verify_bbr
    
    log "INFO" "=== BBR配置流程完成 ==="
}

# 异常处理
trap 'log "ERROR" "脚本执行异常: $BASH_COMMAND (退出码: $?)"; exit 1' ERR

# 检查root权限
if [ "$EUID" -ne 0 ]; then
    echo "请使用sudo权限运行此脚本: sudo $0"
    exit 1
fi

# 执行主函数
main "$@"
