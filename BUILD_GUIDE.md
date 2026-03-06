# CasaOS + Docker 镜像构建指南

## 🚀 快速构建

### 方法1: 本地构建 (需要 Docker)

```bash
# 1. 进入项目目录
cd /path/to/project

# 2. 构建镜像
docker build -t casaos-full:latest .

# 3. 运行容器
docker run -d \
  --name casaos-full \
  --privileged \
  -p 80:80 \
  -p 443:443 \
  -p 2222:22 \
  -p 2375:2375 \
  -v casaos-docker:/var/lib/docker \
  -v casaos-etc:/etc/casaos \
  -v casaos-lib:/var/lib/casaos \
  -v casaos-data:/DATA \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  --cgroupns=host \
  --restart=unless-stopped \
  casaos-full:latest
```

### 方法2: 使用 Docker Compose

```bash
# 构建并启动
docker-compose up -d --build

# 查看日志
docker-compose logs -f

# 停止
docker-compose down
```

### 方法3: GitHub Actions 自动构建

1. **Fork 本仓库** 到你的 GitHub 账户
2. **启用 GitHub Actions**
3. **配置 Secrets** (可选):
   - 不需要额外配置，使用默认 `GITHUB_TOKEN`
4. **触发构建**:
   - 手动触发: 进入 Actions 页面点击 "Run workflow"
   - 自动触发: 推送代码到 main 分支

构建完成后，镜像将推送到 GitHub Container Registry:
```
ghcr.io/YOUR_USERNAME/casaos-full:latest
```

## 📋 构建要求

### 本地构建
- Docker Engine 20.10+
- Docker Compose 2.0+
- Linux 内核 5.0+ (支持 cgroup v2)
- 至少 4GB 内存
- 20GB 磁盘空间

### GitHub Actions 构建
- GitHub 账户
- 启用 GitHub Packages

## 🔧 构建参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `UBUNTU_VERSION` | 24.04 | 基础镜像版本 |
| `DOCKER_VERSION` | latest | Docker 版本 |
| `CASAOS_VERSION` | latest | CasaOS 版本 |

使用参数构建:
```bash
docker build \
  --build-arg UBUNTU_VERSION=22.04 \
  --build-arg DOCKER_VERSION=24.0.7 \
  -t casaos-full:custom .
```

## 📦 多架构构建

### 本地多架构构建

```bash
# 创建 buildx 构建器
docker buildx create --name multiarch --use
docker buildx inspect --bootstrap

# 构建多架构镜像
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t casaos-full:latest \
  --push .
```

### GitHub Actions 多架构

已配置自动构建 `linux/amd64` 和 `linux/arm64` 架构。

## 🧪 测试镜像

```bash
# 1. 运行测试容器
docker run -d --name casaos-test --privileged -p 8080:80 casaos-full:latest

# 2. 等待启动
sleep 30

# 3. 检查服务
docker exec casaos-test docker info
docker exec casaos-test pgrep -f casaos

# 4. 访问测试
curl -I http://localhost:8080

# 5. 清理
docker stop casaos-test && docker rm casaos-test
```

## 🌐 使用预构建镜像

从 GitHub Container Registry 拉取:

```bash
# 登录 (需要 GitHub Token)
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# 拉取镜像
docker pull ghcr.io/USERNAME/casaos-full:latest

# 运行
docker run -d --name casaos --privileged -p 80:80 ghcr.io/USERNAME/casaos-full:latest
```

## 📝 镜像标签说明

| 标签 | 说明 |
|------|------|
| `latest` | 最新稳定版 |
| `main` | 主分支最新构建 |
| `v1.0.0` | 版本标签 |
| `20240101` | 日期标签 |
| `pr-123` | PR 构建 |

## 🔍 故障排除

### 构建失败

```bash
# 清理缓存重新构建
docker build --no-cache -t casaos-full:latest .

# 查看详细日志
docker build --progress=plain -t casaos-full:latest .
```

### 容器无法启动

```bash
# 检查日志
docker logs casaos-full

# 检查 cgroup
docker exec casaos-full mount | grep cgroup

# 重启容器
docker restart casaos-full
```

## 📚 相关链接

- [CasaOS 官网](https://www.casaos.io/)
- [Docker 文档](https://docs.docker.com/)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
