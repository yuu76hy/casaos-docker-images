# CasaOS + Docker 完整镜像
# 基于 Ubuntu 24.04
FROM ubuntu:24.04

LABEL maintainer="CasaOS Docker Image"
LABEL description="Complete CasaOS with Docker-in-Docker support"

# 环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai
ENV DOCKER_VERSION=latest
ENV CASAOS_VERSION=latest

# 安装基础依赖
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    jq \
    tar \
    gzip \
    rclone \
    lsof \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    openssh-server \
    supervisor \
    systemd \
    systemd-sysv \
    dbus \
    dbus-x11 \
    iptables \
    ipset \
    iproute2 \
    kmod \
    udev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 安装 Docker
RUN curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun \
    && systemctl enable docker containerd || true

# 安装 Docker Compose
RUN curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose \
    && ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# 创建管理员用户
RUN useradd -m -s /bin/bash roots \
    && echo "roots:roots" | chpasswd \
    && echo "roots ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/roots \
    && chmod 0440 /etc/sudoers.d/roots \
    && usermod -aG docker roots

# 创建必要目录
RUN mkdir -p /etc/casaos /var/lib/casaos /DATA /var/lib/docker /run/docker /root/.config

# 安装 CasaOS
RUN curl -fsSL https://get.casaos.io | bash \
    && systemctl stop casaos 2>/dev/null || true \
    && systemctl disable casaos 2>/dev/null || true

# 配置 SSH
RUN mkdir -p /var/run/sshd \
    && echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config \
    && echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config

# 创建启动脚本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 创建 Supervisor 配置
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 暴露端口
# 22: SSH
# 80: CasaOS HTTP
# 443: CasaOS HTTPS
# 8080: CasaOS 备用
EXPOSE 22 80 443 8080

# 设置卷
VOLUME ["/var/lib/docker", "/etc/casaos", "/var/lib/casaos", "/DATA", "/root/.config"]

# 启动入口
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
