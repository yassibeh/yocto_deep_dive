ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV STM32CUBE_PROGRAMMER_ROOT=/opt/st/STM32CubeProgrammer
ENV PATH=/opt/st/STM32CubeProgrammer/bin:${PATH}

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    bsdmainutils \
    build-essential \
    ca-certificates \
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
    less \
    libgmp-dev \
    libmpc-dev \
    libsdl1.2-dev \
    libssl-dev \
    libusb-1.0-0 \
    locales \
    lz4 \
    openssh-client \
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
 && locale-gen en_US.UTF-8 \
 && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
 && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash builder

RUN curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo \
 && chmod 0755 /usr/local/bin/repo

ARG STM32CUBEPROG_BUNDLE=
ARG STM32CUBEPROG_DIR=

WORKDIR /workspace

COPY scripts/install-stm32cubeprogrammer.sh /usr/local/bin/install-stm32cubeprogrammer
COPY containers/stm32mp-yocto/entrypoint.sh /usr/local/bin/stm32mp-yocto-entrypoint
RUN chmod 0755 /usr/local/bin/install-stm32cubeprogrammer /usr/local/bin/stm32mp-yocto-entrypoint

COPY . /tmp/yocto_deep_dive
RUN if [ -n "${STM32CUBEPROG_BUNDLE}" ]; then \
        export STM32CUBEPROG_ACCEPT_LICENSE=1; \
        /usr/local/bin/install-stm32cubeprogrammer --from-file "/tmp/yocto_deep_dive/${STM32CUBEPROG_BUNDLE}" --dest "${STM32CUBE_PROGRAMMER_ROOT}"; \
    elif [ -n "${STM32CUBEPROG_DIR}" ]; then \
        /usr/local/bin/install-stm32cubeprogrammer --from-dir "/tmp/yocto_deep_dive/${STM32CUBEPROG_DIR}" --dest "${STM32CUBE_PROGRAMMER_ROOT}"; \
    fi \
 && rm -rf /tmp/yocto_deep_dive

ENTRYPOINT ["/usr/local/bin/stm32mp-yocto-entrypoint"]
CMD ["bash"]
