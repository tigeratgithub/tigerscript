#!/usr/bin/env bash
# Ubuntu 24.04 无头工作站一键安装 Xfce4 + xrdp
# 用法: sudo bash xrdp-xfce.sh [RDP_PORT] [USERNAME]
set -euo pipefail

################  0. 参数检查  ################
if [[ $# -ne 2 ]]; then
  echo "用法: sudo bash $0 <RDP端口> <系统用户名>"
  echo "示例: sudo bash $0 3390 alice"
  exit 1
fi

RDP_PORT=$1
USR=$2

# 检查用户是否存在
if ! id "$USR" &>/dev/null; then
  echo "错误：用户 $USR 不存在，请先创建该用户。"
  exit 2
fi
########################################################

# 必须是 root
if [[ $EUID -ne 0 ]]; then
  echo "请以 sudo 运行: sudo bash $0 $RDP_PORT $USR"
  exit 3
fi

# 1. 更新系统
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get upgrade -yq

# 2. 安装 Xfce4 轻量桌面
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  xfce4 xfce4-goodies xfce4-session dbus-x11

# 3. 安装 xrdp
DEBIAN_FRONTEND=noninteractive apt-get install -y xrdp
adduser xrdp ssl-cert        # 授权证书组，避免黑屏

# 4. 指定会话环境为 Xfce
echo "xfce4-session" > /home/$USR/.xsession
chown $USR:$USR /home/$USR/.xsession

# 5. 配置 xrdp 启动脚本（强制 startxfce4）
cat >/etc/xrdp/startwm.sh <<'EOF'
#!/bin/sh
if [ -r /etc/default/locale ]; then
  . /etc/default/locale
  export LANG LANGUAGE
fi
startxfce4
EOF
chmod +x /etc/xrdp/startwm.sh

# 6. 修改端口
sed -i "s/^port=.*/port=$RDP_PORT/" /etc/xrdp/xrdp.ini

# 7. 防火墙放行
if command -v ufw &>/dev/null; then
  ufw allow "$RDP_PORT/tcp" comment 'xrdp'
fi

# 8. 启动并设为开机自启
systemctl enable --now xrdp
systemctl restart xrdp

# 9. 打印信息
echo "=================================================="
echo "Xfce4 + xrdp 安装完成！"
echo "RDP 端口：$RDP_PORT"
echo "登录用户：$USR （使用系统账号密码）"
echo "=================================================="
