#!/bin/bash

# --- 默认值设置 ---
DNS="kline.tomcatio.top"  # 你的域名
DIR="/home/tiger/mywork/money/mosquitto" # 证书存放目录
PROJECT_PATH="/home/tiger/mywork/money" # 你的 docker-compose.yml 所在的目录
SERVICE_NAME="mosquitto"      # compose 文件里的服务名

# --- 解析键值对参数 ---
for arg in "$@"; do
  case $arg in
    dns=*)
      DNS="${arg#*=}"
      shift
      ;;
    key_dir=*)
      DIR="${arg#*=}"
      shift
      ;;
    project_path=*)
      PROJECT_PATH="${arg#*=}"
      shift
      ;;
    service=*)
      SERVICE_NAME="${arg#*=}"
      shift
      ;;
  esac
done

# --- 逻辑检查 ---
if [ -z "$DNS" ]; then
    echo "错误: 必须提供 dns 参数 (例如: dns=mqtt.example.com)"
    exit 1
fi

# --- 执行续期与拷贝逻辑 ---
echo "正在为域名: $DNS 处理证书..."

# 1. 尝试续期
certbot renew --quiet

# 2. 检查并拷贝
SOURCE_DIR="/etc/letsencrypt/live/$DNS"
if [ -f "$SOURCE_DIR/fullchain.pem" ]; then
    mkdir -p "$DIR"
    cp -L "$SOURCE_DIR/fullchain.pem" "$DIR/server.crt"
    cp -L "$SOURCE_DIR/privkey.pem" "$DIR/server.key"
    
    # 3. 设置权限 (1883 是 Mosquitto 镜像默认用户)
    chown 1883:1883 "$DIR/server.crt" "$DIR/server.key"
    chmod 644 "$DIR/server.crt"
    chmod 600 "$DIR/server.key"

    # 4. 使用 docker-compose 重启服务
    # 我们进入 compose 文件所在目录执行操作
    if [ -d "$PROJECT_PATH" ]; then
        cd "$PROJECT_PATH" || exit
        # 使用 docker compose (新版) 或 docker-compose (旧版)
        docker compose restart "$SERVICE_NAME"
        echo "[$DNS] 证书更新成功，Compose服务 $SERVICE_NAME 已重启。" >> /var/log/mqtt_cert_renew.log
    else
        echo "错误: 未找到 Compose 项目目录 $PROJECT_PATH"
        exit 1
    fi
else
    echo "错误: 在 $SOURCE_DIR 未找到证书文件。"
    exit 1
fi