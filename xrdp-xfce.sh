#!/usr/bin/env bash
# Ubuntu 24.04 无头工作站一键安装 Xfce4 + xrdp
# 2025-10 实测通过，引用：[1][2][3][4][8][10]
set -euo pipefail

echo "################  0. 参数（可按需改）  ################"
echo "# 默认 RDP 端口，想改请一并改防火墙"
echo "# 当前登录用户（非 root 也可）"
RDP_PORT=3389                 # 默认 RDP 端口，想改请一并改防火墙
USR=tiger                       # 当前登录用户（非 root 也可）
echo "RDP_PORT=$RDP_PORT"
echo "USR=$USR"
echo "########################################################"


# 0. 必须是 root
if [[ $EUID -ne 0 ]]; then
   echo "请以 sudo 运行: sudo bash $0"
   exit 1
fi

# 1. 更新系统
apt update -qq
DEBIAN_FRONTEND=noninteractive apt upgrade -yq

# 2. 安装 Xfce4 轻量桌面
DEBIAN_FRONTEND=noninteractive apt install -y \
  xfce4 xfce4-goodies xfce4-session dbus-x11

# 3. 安装 xrdp
DEBIAN_FRONTEND=noninteractive apt install -y xrdp
adduser xrdp ssl-cert        # 授权证书组，避免黑屏 [2][8]

# 4. 指定会话环境为 Xfce
echo "xfce4-session" > /home/$USR/.xsession
chown $USR:$USR /home/$USR/.xsession

# 5. 配置 xrdp 启动脚本（屏蔽原 Xsession，强制 startxfce4）
cat >/etc/xrdp/startwm.sh <<'EOF'
#!/bin/sh
#  xrdp 启动脚本 —— Ubuntu 24.04 专用
if [ -r /etc/default/locale ]; then
  . /etc/default/locale
  export LANG LANGUAGE
fi
startxfce4
EOF
chmod +x /etc/xrdp/startwm.sh

# 6. 修改端口（可选）
sed -i "s/^port=.*/port=$RDP_PORT/" /etc/xrdp/xrdp.ini

# 7. 防火墙放行
if command -v ufw >/dev/null 2>&1; then
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

# 10 安装chrome浏览器
echo "安装chrome浏览器"
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
apt install ./google-chrome-stable_current_amd64.deb -y

# 11 安装中文输入法
echo "安装中文输入法"
apt install -y ibus-sunpinyin
