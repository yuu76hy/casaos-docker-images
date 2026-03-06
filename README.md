# CasaOS + Docker 完整镜像

这是一个包含 CasaOS 和 Docker (Docker-in-Docker) 的完整容器镜像，可以在容器中运行 CasaOS 并使用 Docker 部署其他应用。

## 📋 功能特性

- ✅ **CasaOS** - 开源的家庭云系统
- ✅ **Docker-in-Docker** - 在容器内运行 Docker
- ✅ **Docker Compose** - 支持多容器编排
- ✅ **SSH 服务** - 内置 SSH 远程访问
- ✅ **Supervisor** - 进程管理
- ✅ **数据持久化** - 重要数据使用 Docker Volume

## 🚀 快速开始

### 方式1: 使用 Docker Compose (推荐)

```bash
# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

### 方式2: 使用 Docker 命令

```bash
# 运行容器
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

## 📦 构建镜像

```bash
# 使用构建脚本
chmod +x build.sh
./build.sh

# 或直接构建
docker build -t casaos-full:latest .
```

## 🔌 访问服务

| 服务 | 地址 | 说明 |
|------|------|------|
| CasaOS Web | http://localhost:80 | CasaOS 主界面 |
| CasaOS HTTPS | https://localhost:443 | CasaOS 安全访问 |
| SSH | localhost:2222 | SSH 远程访问 |
| Docker API | localhost:2375 | Docker API 端口 |

### 默认账户

- **SSH 用户名**: `roots`
- **SSH 密码**: `roots`
- **CasaOS**: 首次访问需要设置

## 📁 目录结构

```
.
├── Dockerfile              # 镜像构建文件
├── docker-compose.yml      # Docker Compose 配置
├── entrypoint.sh           # 容器入口脚本
├── supervisord.conf        # Supervisor 进程管理配置
├── build.sh                # 构建脚本
└── README.md               # 说明文档
```

## 🔧 高级配置

### 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `TZ` | Asia/Shanghai | 时区设置 |
| `DEBIAN_FRONTEND` | noninteractive | 非交互式安装 |

### 数据卷

| 卷名 | 挂载路径 | 说明 |
|------|----------|------|
| `docker-data` | /var/lib/docker | Docker 数据 |
| `casaos-etc` | /etc/casaos | CasaOS 配置 |
| `casaos-lib` | /var/lib/casaos | CasaOS 数据 |
| `casaos-data` | /DATA | 用户数据目录 |
| `root-config` | /root/.config | 根用户配置 |

## 🛠️ 常用命令

```bash
# 进入容器
docker exec -it casaos-full bash

# 查看容器日志
docker logs -f casaos-full

# 查看 CasaOS 状态
docker exec casaos-full systemctl status casaos

# 重启 CasaOS
docker exec casaos-full systemctl restart casaos

# 查看 Docker 状态
docker exec casaos-full docker info

# 在容器内运行 Docker 命令
docker exec casaos-full docker ps
docker exec casaos-full docker images
```

## ⚠️ 注意事项

1. **特权模式**: 容器需要使用 `--privileged` 模式运行，以支持 Docker-in-Docker
2. **cgroup**: 需要挂载主机的 cgroup 目录以支持容器管理
3. **端口冲突**: 如果主机 80/443 端口被占用，请修改端口映射
4. **资源限制**: CasaOS 和 Docker 需要足够的内存和 CPU 资源

## 🔒 安全建议

1. 修改默认 SSH 密码
2. 配置 CasaOS 访问密码
3. 限制 Docker API 访问 (2375 端口)
4. 使用防火墙限制端口访问

## 🐛 故障排除

### Docker 无法启动

```bash
# 检查 cgroup 挂载
docker exec casaos-full mount | grep cgroup

# 重启 Docker 服务
docker exec casaos-full systemctl restart docker
```

### CasaOS 无法访问

```bash
# 检查 CasaOS 状态
docker exec casaos-full pgrep -f casaos

# 重启 CasaOS
docker exec casaos-full systemctl restart casaos
```

## 📄 许可证

本项目基于开源协议，仅供学习和个人使用。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来改进这个项目。
