#!/bin/bash
set -e

echo "=========================================="
echo "  CasaOS + Docker 容器启动脚本"
echo "=========================================="

# 挂载 cgroup v2 支持（如果需要）
if [ -f /sys/fs/cgroup/cgroup.controllers ]; then
    echo "📌 检测到 cgroup v2，配置容器支持..."
    mkdir -p /sys/fs/cgroup/init
    echo 1 > /sys/fs/cgroup/init/cgroup.procs 2>/dev/null || true
fi

# 配置 Docker 守护进程
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2375"],
  "insecure-registries": []
}
EOF

# 启动 Docker 守护进程
echo "🐳 启动 Docker 守护进程..."
if ! pgrep -x "dockerd" > /dev/null; then
    dockerd &
    sleep 5
fi

# 等待 Docker 就绪
echo "⏳ 等待 Docker 就绪..."
for i in {1..30}; do
    if docker info >/dev/null 2>&1; then
        echo "✅ Docker 守护进程已启动"
        break
    fi
    echo "  等待中... ($i/30)"
    sleep 1
done

if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker 启动失败"
    exit 1
fi

# 显示 Docker 版本
echo "📌 Docker 版本:"
docker --version
docker-compose --version

# 配置权限
echo "🔧 配置 CasaOS 目录权限..."
mkdir -p /etc/casaos /var/lib/casaos /DATA /root/.config
chown -R root:root /etc/casaos /var/lib/casaos /DATA /root/.config
chmod -R 755 /etc/casaos
chmod -R 700 /var/lib/casaos

# 启动 CasaOS
echo "🏠 启动 CasaOS..."
if [ -f /etc/systemd/system/casaos.service ]; then
    systemctl start casaos 2>/dev/null || true
elif [ -f /usr/bin/casaos ]; then
    casaos &
    sleep 3
else
    # 手动启动 CasaOS 服务
    if [ -f /usr/local/bin/casaos ]; then
        /usr/local/bin/casaos &
        sleep 3
    fi
fi

# 检查 CasaOS 状态
echo "📌 CasaOS 状态检查..."
if pgrep -f "casaos" > /dev/null; then
    echo "✅ CasaOS 进程已启动"
else
    echo "⚠️ CasaOS 进程未检测到，尝试重新启动..."
    # 尝试使用 systemd 启动
    if command -v systemctl >/dev/null 2>&1; then
        systemctl daemon-reload 2>/dev/null || true
        systemctl enable casaos 2>/dev/null || true
        systemctl start casaos 2>/dev/null || true
    fi
fi

# 启动 SSH 服务
echo "🔑 启动 SSH 服务..."
mkdir -p /var/run/sshd
/usr/sbin/sshd

# 显示访问信息
echo ""
echo "=========================================="
echo "  🎉 服务启动完成！"
echo "=========================================="
echo ""
echo "📌 访问信息:"
echo "  - CasaOS Web: http://localhost:80"
echo "  - CasaOS Web (HTTPS): https://localhost:443"
echo "  - SSH: localhost:22 (用户名: roots, 密码: roots)"
echo "  - Docker API: tcp://localhost:2375"
echo ""
echo "📌 常用命令:"
echo "  - docker ps        # 查看容器"
echo "  - docker images    # 查看镜像"
echo "  - casaos --help    # CasaOS 帮助"
echo ""
echo "=========================================="

# 执行传入的命令
exec "$@"
