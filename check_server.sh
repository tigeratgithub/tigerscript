#!/bin/bash
# ============================================================
# Linux 服务器全量盘点脚本
# 输出文件：server_info_HOSTNAME_DATE.txt
# 执行建议：root 权限
# chmod +x check_server.sh
# sudo ./checck_server.sh
# ============================================================

HOST=$(hostname)
DATE=$(date +%F_%H-%M-%S)
OUT="server_info_${HOST}_${DATE}.txt"

# 所有输出写入文件
exec > >(tee -i "$OUT")
exec 2>&1

echo "============================================================"
echo "🖥️  开始盘点服务器：$HOST"
echo "📅  时间：$(date)"
echo "📄  输出文件：$OUT"
echo "============================================================"

step() {
    echo ""
    echo "############################################################"
    echo "🔹 $1"
    echo "############################################################"
}

# ------------------------------------------------------------
step "1️⃣ 系统基本信息"
# ------------------------------------------------------------
hostnamectl
cat /etc/os-release
uname -a
uptime
whoami
echo "PATH=$PATH"

# ------------------------------------------------------------
step "2️⃣ 正在运行的服务"
# ------------------------------------------------------------
systemctl list-units --type=service --state=running

# ------------------------------------------------------------
step "3️⃣ 监听端口（含进程）"
# ------------------------------------------------------------
ss -lntup
echo ""
netstat -lntup 2>/dev/null || echo "netstat 未安装"

# ------------------------------------------------------------
step "4️⃣ 开机自启服务"
# ------------------------------------------------------------
systemctl list-unit-files --type=service --state=enabled

# ------------------------------------------------------------
step "5️⃣ 已安装软件包"
# ------------------------------------------------------------
if command -v dpkg >/dev/null 2>&1; then
    echo "【Debian / Ubuntu】"
    dpkg -l | wc -l
    dpkg -l | tail -n 30
elif command -v rpm >/dev/null 2>&1; then
    echo "【RHEL / CentOS / Rocky / Alma】"
    rpm -qa --last | head -30
else
    echo "无法识别包管理器"
fi

# ------------------------------------------------------------
step "6️⃣ 定时任务"
# ------------------------------------------------------------
echo "== 当前用户 crontab =="
crontab -l 2>/dev/null || echo "无"

echo ""
echo "== root crontab =="
sudo crontab -l 2>/dev/null || echo "无"

echo ""
echo "== /etc/crontab =="
cat /etc/crontab 2>/dev/null

echo ""
echo "== cron.d =="
ls -l /etc/cron.d/

echo ""
echo "== systemd timers =="
systemctl list-timers --all

# ------------------------------------------------------------
step "7️⃣ 启动项"
# ------------------------------------------------------------
ls -l /etc/rc*.d/ 2>/dev/null
cat /etc/rc.local 2>/dev/null
ls -l /etc/profile.d/
cat /etc/bash.bashrc 2>/dev/null

# ------------------------------------------------------------
step "8️⃣ 历史操作记录"
# ------------------------------------------------------------
echo "== shell history =="
history | tail -n 50

echo ""
echo "== apt 安装历史 =="
grep "install" /var/log/apt/history.log 2>/dev/null | tail -n 30

echo ""
echo "== yum/dnf 安装历史 =="
grep -h "Installed" /var/log/yum.log 2>/dev/null | tail -n 30
dnf history 2>/dev/null | head -20

# ------------------------------------------------------------
step "9️⃣ 配置文件变更（近90天）"
# ------------------------------------------------------------
find /etc -type f -mtime -90 2>/dev/null | sort | tail -n 50

# ------------------------------------------------------------
step "🔟 用户 & 权限"
# ------------------------------------------------------------
echo "== 可登录用户 =="
awk -F: '$7 !~ /nologin|false/ {print $1,$7}' /etc/passwd

echo ""
echo "== sudo 权限 =="
ls -l /etc/sudoers.d/
grep -R "ALL=(ALL)" /etc/sudoers* 2>/dev/null

echo ""
echo "== SSH 登录记录 =="
last | head -20
lastlog | head -20

# ------------------------------------------------------------
step "1️⃣1️⃣ 磁盘 & 挂载"
# ------------------------------------------------------------
lsblk -f
df -hT
mount | column -t
cat /etc/fstab

# ------------------------------------------------------------
step "1️⃣2️⃣ 大目录 & 大文件"
# ------------------------------------------------------------
du -sh /* 2>/dev/null | sort -h | tail -20
du -sh /home/* /var/* /opt/* 2>/dev/null | sort -h | tail -20

echo ""
echo "== 大于 500M 的文件 =="
find / -type f -size +500M 2>/dev/null | head -20

# ------------------------------------------------------------
step "1️⃣3️⃣ Docker"
# ------------------------------------------------------------
if command -v docker >/dev/null 2>&1; then
    docker ps -a
    docker images
    docker volume ls
    docker network ls
    echo ""
    find / -name docker-compose.yml 2>/dev/null | head -10
else
    echo "Docker 未安装"
fi

# ------------------------------------------------------------
step "1️⃣4️⃣ Kubernetes"
# ------------------------------------------------------------
if command -v kubectl >/dev/null 2>&1; then
    kubectl get nodes
    kubectl get all -A
else
    echo "kubectl 未安装"
fi

# ------------------------------------------------------------
step "1️⃣5️⃣ 防火墙"
# ------------------------------------------------------------
echo "== UFW =="
ufw status verbose 2>/dev/null || echo "UFW 未启用"

echo ""
echo "== firewalld =="
systemctl status firewalld --no-pager 2>/dev/null

echo ""
echo "== iptables =="
iptables -L -n -v 2>/dev/null | head -40

echo ""
echo "== nftables =="
systemctl status nftables --no-pager 2>/dev/null

# ------------------------------------------------------------
step "1️⃣6️⃣ Web / DB / 中间件"
# ------------------------------------------------------------
ps -ef | grep -E 'nginx|httpd|apache|mysql|mariadb|postgres|redis|mongo|java|node|python' | grep -v grep

echo ""
echo "== 常见配置目录 =="
ls -ld /etc/nginx /etc/mysql /etc/redis /etc/postgresql /usr/local/* /opt/* 2>/dev/null

# ------------------------------------------------------------
step "✅ 盘点完成"
# ------------------------------------------------------------
echo ""
echo "✅ 所有信息已记录到：$OUT"
echo "📌 请将该文件内容完整发送给我，我来帮你分析"
echo ""

exit 0
