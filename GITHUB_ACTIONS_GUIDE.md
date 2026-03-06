# GitHub Actions 自动构建指南

## 🚀 快速开始

### 步骤1: 创建 GitHub 仓库

1. 访问 https://github.com/new
2. 输入仓库名称，例如 `casaos-docker`
3. 选择 **Public** 或 **Private**
4. 点击 **Create repository**

### 步骤2: 上传代码到 GitHub

```bash
# 初始化 Git 仓库
cd c:\Users\User\Desktop\opt
git init

# 添加所有文件
git add .

# 提交
git commit -m "Initial commit: CasaOS + Docker 镜像"

# 添加远程仓库 (替换 YOUR_USERNAME 和 REPO_NAME)
git remote add origin https://github.com/YOUR_USERNAME/REPO_NAME.git

# 推送代码
git push -u origin main
```

### 步骤3: 启用 GitHub Packages

1. 进入仓库页面
2. 点击 **Settings** → **Packages**
3. 确保 **Inherit access from source repository** 已启用

### 步骤4: 触发构建

#### 方式A: 手动触发
1. 进入仓库页面
2. 点击 **Actions** 标签
3. 选择 **Build CasaOS + Docker Image**
4. 点击 **Run workflow**

#### 方式B: 自动触发
- 推送代码到 `main` 或 `master` 分支
- 修改 `Dockerfile`、`entrypoint.sh` 或 `supervisord.conf`

## 📋 构建流程说明

```
┌─────────────────────────────────────────────────────────┐
│  GitHub Actions 构建流程                                 │
├─────────────────────────────────────────────────────────┤
│  1. Checkout 代码                                        │
│  2. 设置 QEMU (多架构支持)                               │
│  3. 设置 Docker Buildx                                   │
│  4. 登录 GitHub Container Registry                       │
│  5. 提取镜像元数据                                       │
│  6. 构建多架构镜像 (amd64/arm64)                         │
│  7. 推送镜像到 GHCR                                      │
│  8. 生成 SBOM 清单                                       │
│  9. 安全漏洞扫描                                         │
│  10. 上传扫描结果                                        │
│  11. 测试镜像                                            │
└─────────────────────────────────────────────────────────┘
```

## 🏷️ 生成的镜像标签

构建完成后，你将获得以下标签：

| 标签 | 示例 | 说明 |
|------|------|------|
| `latest` | `ghcr.io/user/casaos-full:latest` | 最新稳定版 |
| `main` | `ghcr.io/user/casaos-full:main` | 主分支构建 |
| 日期 | `ghcr.io/user/casaos-full:20240306` | 定时构建 |
| PR | `ghcr.io/user/casaos-full:pr-1` | PR 构建 |

## 🔐 认证配置

### 方式1: 使用 GITHUB_TOKEN (推荐)

工作流已配置使用 `GITHUB_TOKEN`，无需额外设置。

### 方式2: 使用 Personal Access Token (PAT)

如果需要跨仓库访问，创建 PAT：

1. 访问 https://github.com/settings/tokens
2. 点击 **Generate new token (classic)**
3. 勾选权限:
   - `read:packages`
   - `write:packages`
   - `delete:packages`
4. 复制 Token
5. 在仓库 Settings → Secrets → Actions 中添加:
   - Name: `CR_PAT`
   - Value: 你的 Token

## 📥 使用构建好的镜像

### 登录 GitHub Container Registry

```bash
# 使用 GITHUB_TOKEN
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# 或使用 PAT
echo $CR_PAT | docker login ghcr.io -u USERNAME --password-stdin
```

### 拉取并运行

```bash
# 拉取镜像
docker pull ghcr.io/YOUR_USERNAME/casaos-full:latest

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
  ghcr.io/YOUR_USERNAME/casaos-full:latest
```

## ⚙️ 自定义配置

### 修改镜像名称

编辑 `.github/workflows/build-casaos-docker.yml`:

```yaml
env:
  REGISTRY: ghcr.io
  IMAGE_NAME: your-custom-name  # 修改这里
```

### 修改触发条件

```yaml
on:
  workflow_dispatch:  # 手动触发
  push:
    branches: [ main ]
  schedule:
    - cron: '0 0 * * 0'  # 每周日构建
```

### 添加构建参数

```yaml
- name: Build and push Docker image
  uses: docker/build-push-action@v5
  with:
    build-args: |
      UBUNTU_VERSION=22.04
      DOCKER_VERSION=24.0.7
      CASAOS_VERSION=0.4.8
```

## 🔍 查看构建结果

### 在 GitHub 上查看

1. 进入仓库 → **Actions** 标签
2. 点击工作流运行记录
3. 查看每个步骤的日志

### 查看镜像

1. 点击个人头像 → **Your packages**
2. 找到 `casaos-full` 镜像
3. 查看标签和详细信息

### 下载 SBOM 和扫描报告

构建完成后，在 Actions 页面的 **Artifacts** 部分下载:
- `sbom.spdx.json` - 软件物料清单
- `trivy-results.sarif` - 安全扫描报告

## 🐛 故障排除

### 构建失败

```bash
# 检查工作流日志
# 进入 Actions → 失败的运行 → 查看日志
```

常见原因:
- Dockerfile 语法错误
- 网络问题导致下载失败
- 权限不足

### 镜像推送失败

1. 检查仓库权限
2. 确认 `packages: write` 权限已启用
3. 检查是否超出存储配额

### 测试失败

```bash
# 本地测试镜像
docker build -t casaos-test .
docker run --rm --privileged casaos-test
```

## 📊 监控构建

### 启用通知

在仓库 Settings → Notifications 中配置构建通知。

### 查看构建统计

进入 Insights → Actions 查看构建历史和统计。

## 🎉 完成！

构建完成后，你将拥有:
- ✅ 多架构 Docker 镜像 (amd64/arm64)
- ✅ 自动安全扫描
- ✅ SBOM 软件清单
- ✅ 版本标签管理
- ✅ 自动化测试

现在你可以在任何支持 Docker 的环境中使用这个镜像了！
