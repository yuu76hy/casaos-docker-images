#!/bin/bash
set -e

# CasaOS + Docker 镜像构建脚本
# 支持 Linux/macOS/WSL

echo "=========================================="
echo "  CasaOS + Docker 镜像构建脚本"
echo "=========================================="

# 镜像名称和标签
IMAGE_NAME="${IMAGE_NAME:-casaos-full}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

echo ""
echo "📌 构建信息:"
echo "  - 镜像名称: ${IMAGE_NAME}"
echo "  - 镜像标签: ${IMAGE_TAG}"
echo "  - 完整名称: ${FULL_IMAGE_NAME}"
echo ""

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ 错误: Docker 未安装"
    exit 1
fi

echo "✅ Docker 已安装: $(docker --version)"

# 检查 Docker Compose 是否安装
if command -v docker-compose &> /dev/null; then
    echo "✅ Docker Compose 已安装: $(docker-compose --version)"
    COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    echo "✅ Docker Compose (Plugin) 已安装"
    COMPOSE_CMD="docker compose"
else
    echo "⚠️ 警告: Docker Compose 未安装"
    COMPOSE_CMD=""
fi

echo ""
echo "🔨 开始构建镜像..."
docker build -t "${FULL_IMAGE_NAME}" -f Dockerfile .

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 镜像构建成功!"
    echo ""
    echo "📌 镜像信息:"
    docker images "${FULL_IMAGE_NAME}" --format "  - ID: {{.ID}} | 大小: {{.Size}} | 创建时间: {{.CreatedAt}}"
    echo ""
    echo "🚀 运行方式:"
    echo ""
    echo "  方式1 - 使用 Docker Compose (推荐):"
    echo "    ${COMPOSE_CMD:-docker compose} up -d"
    echo ""
    echo "  方式2 - 使用 Docker 命令:"
    echo "    docker run -d \\"
    echo "      --name casaos-full \\"
    echo "      --privileged \\"
    echo "      -p 80:80 \\"
    echo "      -p 443:443 \\"
    echo "      -p 2222:22 \\"
    echo "      -p 2375:2375 \\"
    echo "      -v casaos-docker:/var/lib/docker \\"
    echo "      -v casaos-etc:/etc/casaos \\"
    echo "      -v casaos-lib:/var/lib/casaos \\"
    echo "      -v casaos-data:/DATA \\"
    echo "      -v /sys/fs/cgroup:/sys/fs/cgroup:rw \\"
    echo "      --cgroupns=host \\"
    echo "      --restart=unless-stopped \\"
    echo "      ${FULL_IMAGE_NAME}"
    echo ""
    echo "📌 访问地址:"
    echo "  - CasaOS Web: http://localhost:80"
    echo "  - CasaOS HTTPS: https://localhost:443"
    echo "  - SSH: ssh roots@localhost -p 2222 (密码: roots)"
    echo ""
else
    echo ""
    echo "❌ 镜像构建失败!"
    exit 1
fi
