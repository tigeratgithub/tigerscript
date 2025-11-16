#!/bin/bash

# 检查是否传入了用户名参数
if [ -z "$1" ]; then
    echo "使用方法: sudo $0 <用户名>"
    echo "示例: sudo $0 tiger"
    exit 1
fi

# 定义要添加到 docker 组的用户名，从第一个命令行参数获取
TARGET_USER="$1"

# 检查当前是否为 root 用户
if [ "$(id -u)" -ne 0 ]; then
    echo "此脚本需要 root 权限，请使用 sudo 运行。"
    exit 1
fi

# 检查目标用户是否存在
if ! id "$TARGET_USER" &>/dev/null; then
    echo "错误：用户 '$TARGET_USER' 不存在。请确认用户名是否正确。"
    exit 1
fi

echo "--- 🛠️ 开始在 Ubuntu 24.04 上安装 Docker Engine 并为用户 '$TARGET_USER' 配置非 root 权限 ---"

# 1. 更新软件包列表并安装依赖项
echo "1. 更新系统并安装依赖项..."
apt update -y
apt install -y ca-certificates curl gnupg

# 2. 添加 Docker 官方 GPG 密钥
echo "2. 添加 Docker GPG 密钥..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# 3. 设置 Docker APT 软件源
echo "3. 设置 Docker APT 软件源..."
# 确定 Ubuntu 版本代号 (通常是 noble for 24.04)
UBUNTU_CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $UBUNTU_CODENAME stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
  
# 4. 安装 Docker Engine
echo "4. 安装 Docker Engine、CLI、containerd 和 Docker Compose 插件..."
apt update -y
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 5. 将用户添加到 docker 组
echo "5. 将用户 '$TARGET_USER' 添加到 'docker' 组..."
usermod -aG docker "$TARGET_USER"
echo "用户 '$TARGET_USER' 已成功添加到 'docker' 组。"

sudo systemctl status docker
sudo systemctl start docker

# 6. 验证安装
echo "--- ✅ 安装完成 ---"
echo "Docker 版本："
docker --version
echo "Docker Compose 版本："
docker compose version

# 提示用户操作
echo ""
echo "--- ℹ️ 重要提示 ---"
echo "为使 '$TARGET_USER' 用户无需使用 sudo 即可运行 Docker，您需要执行以下操作之一："
echo "1. **注销并重新登录** (推荐): 这样会完全刷新您的用户组权限。"
echo "2. **运行 'newgrp docker'**: 这将在当前 shell 中激活新的 'docker' 组权限。"
echo "在完成上述步骤后，您可以以 '$TARGET_USER' 身份运行 'docker run hello-world' 来验证安装。"
echo "-------------------"



