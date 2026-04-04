FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    bsdmainutils \
    build-essential \
    chrpath \
    cpio \
    curl \
    debianutils \
    diffstat \
    file \
    gawk \
    gcc-multilib \
    git \
    git-lfs \
    iputils-ping \
    libgmp-dev \
    libmpc-dev \
    libsdl1.2-dev \
    libssl-dev \
    libusb-1.0-0 \
    lz4 \
    python3 \
    python3-git \
    python3-jinja2 \
    python3-pexpect \
    python3-pip \
    pylint \
    rsync \
    socat \
    sudo \
    texinfo \
    unzip \
    wget \
    xterm \
    xz-utils \
    zstd \
 && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash builder

RUN curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo \
 && chmod 0755 /usr/local/bin/repo

WORKDIR /workspace

COPY containers/stm32mp-yocto/entrypoint.sh /usr/local/bin/stm32mp-yocto-entrypoint
RUN chmod 0755 /usr/local/bin/stm32mp-yocto-entrypoint

ENTRYPOINT ["/usr/local/bin/stm32mp-yocto-entrypoint"]
CMD ["bash"]
