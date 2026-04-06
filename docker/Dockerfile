ARG BASE_IMAGE=ghcr.io/openwrt/buildbot/buildworker-v3.8.0:v9

FROM ${BASE_IMAGE} AS deps

USER root

ENV DEBIAN_FRONTEND=noninteractive

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    clang \
    file \
    flex \
    g++ \
    g++-multilib \
    gawk \
    gcc-multilib \
    gettext \
    git \
    golang-go \
    libcap-dev \
    libgps-dev \
    libncurses5-dev \
    libnl-3-dev \
    libnl-genl-3-dev \
    libopus-dev \
    libopusfile-dev \
    libpcre3 \
    libpcre3-dev \
    libssl-dev \
    net-tools \
    patch \
    pkg-config \
    portaudio19-dev \
    python3 \
    python3-setuptools \
    rsync \
    swig \
    time \
    unzip \
    upx-ucl \
    wget \
    xz-utils \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

FROM deps AS builder

WORKDIR /workspace/firmware

CMD ["/bin/bash"]
