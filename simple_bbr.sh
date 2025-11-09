#!/usr/bin/env bash
# Ubuntu 24.04 一键永久启用 BBR 拥塞控制算法
# 用法: sudo bash set-bbr.sh
set -euo pipefail

[[ $EUID -ne 0 ]] && { echo "请以 sudo 运行: sudo bash $0"; exit 1; }

# 1. 写入 sysctl 配置
cat >/etc/sysctl.d/99-bbr.conf <<EOF
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF

# 2. 立即生效
sysctl -p /etc/sysctl.d/99-bbr.conf >/dev/null

# 3. 验证
cc=$(sysctl -n net.ipv4.tcp_congestion_control)
if [[ "$cc" == "bbr" ]]; then
  echo "BBR 已启用并设置为默认拥塞控制算法。"
else
  echo "失败！当前算法：$cc" >&2
  exit 2
fi
