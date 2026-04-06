#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

IMAGE_NAME="${IMAGE_NAME:-openmanet-wio-wm6108-wm1302-builder}"
OUTPUT_DIR="${OUTPUT_DIR:-${REPO_ROOT}/artifacts/wio-wm6108-wm1302}"
DL_DIR="${DL_DIR:-${REPO_ROOT}/dl}"
CCACHE_DIR="${CCACHE_DIR:-${REPO_ROOT}/.ccache}"
JOBS="${JOBS:-$(nproc)}"
KEEP_CONTAINER="${KEEP_CONTAINER:-0}"

mkdir -p "${OUTPUT_DIR}" "${DL_DIR}" "${CCACHE_DIR}"

docker build -t "${IMAGE_NAME}" -f "${REPO_ROOT}/docker/Dockerfile" "${REPO_ROOT}"

DOCKER_ARGS=(
    --rm
    --user "$(id -u):$(id -g)"
    --workdir /workspace/firmware
    -e HOME=/tmp/openmanet-home
    -e CCACHE_DIR=/workspace/firmware/.ccache
    -e JOBS="${JOBS}"
    -v "${REPO_ROOT}:/workspace/firmware"
    -v "${DL_DIR}:/workspace/firmware/dl"
    -v "${CCACHE_DIR}:/workspace/firmware/.ccache"
    -v "${OUTPUT_DIR}:/out"
)

if [[ "${KEEP_CONTAINER}" == "1" ]]; then
    DOCKER_ARGS=(
        --user "$(id -u):$(id -g)"
        --workdir /workspace/firmware
        -e HOME=/tmp/openmanet-home
        -e CCACHE_DIR=/workspace/firmware/.ccache
        -e JOBS="${JOBS}"
        -v "${REPO_ROOT}:/workspace/firmware"
        -v "${DL_DIR}:/workspace/firmware/dl"
        -v "${CCACHE_DIR}:/workspace/firmware/.ccache"
        -v "${OUTPUT_DIR}:/out"
    )
fi

docker run "${DOCKER_ARGS[@]}" "${IMAGE_NAME}" /bin/bash -lc '
    set -euo pipefail

    mkdir -p "$HOME"

    ./scripts/openmanet_setup.sh -i -b ekh-bcm2711

    sed -i \
        -e "s/^CONFIG_TARGET_DEVICE_bcm27xx_bcm2711_DEVICE_rpi-4-mmeval=y/# CONFIG_TARGET_DEVICE_bcm27xx_bcm2711_DEVICE_rpi-4-mmeval is not set/" \
        -e "s/^CONFIG_TARGET_DEVICE_bcm27xx_bcm2711_DEVICE_morse_ekh01=y/# CONFIG_TARGET_DEVICE_bcm27xx_bcm2711_DEVICE_morse_ekh01 is not set/" \
        -e "s/^CONFIG_TARGET_DEVICE_bcm27xx_bcm2711_DEVICE_morse_mmx108-ekh01-sdio=y/# CONFIG_TARGET_DEVICE_bcm27xx_bcm2711_DEVICE_morse_mmx108-ekh01-sdio is not set/" \
        -e "s/^CONFIG_TARGET_DEVICE_bcm27xx_bcm2711_DEVICE_morse_mm8108-ekh01-spi=y/# CONFIG_TARGET_DEVICE_bcm27xx_bcm2711_DEVICE_morse_mm8108-ekh01-spi is not set/" \
        -e "s/^CONFIG_TARGET_DEVICE_bcm27xx_bcm2711_DEVICE_morse_mm6108-ekh01-spi=y/# CONFIG_TARGET_DEVICE_bcm27xx_bcm2711_DEVICE_morse_mm6108-ekh01-spi is not set/" \
        -e "s/^CONFIG_TARGET_DEVICE_bcm27xx_bcm2711_DEVICE_morse_mm6108-ekh01-sdio=y/# CONFIG_TARGET_DEVICE_bcm27xx_bcm2711_DEVICE_morse_mm6108-ekh01-sdio is not set/" \
        -e "s/^CONFIG_TARGET_DEVICE_bcm27xx_bcm2711_DEVICE_bcm2711_mm6108-sdio=y/# CONFIG_TARGET_DEVICE_bcm27xx_bcm2711_DEVICE_bcm2711_mm6108-sdio is not set/" \
        -e "s/^CONFIG_TARGET_DEVICE_bcm27xx_bcm2711_DEVICE_bcm2711_mm8108-usb=y/# CONFIG_TARGET_DEVICE_bcm27xx_bcm2711_DEVICE_bcm2711_mm8108-usb is not set/" \
        .config

    make defconfig
    make download -j"${JOBS}"
    make -j"${JOBS}"

    TARGET_DIR="bin/targets/bcm27xx/bcm2711"
    ARTIFACT_NAME="$(find "${TARGET_DIR}" -maxdepth 1 -type f -iname "*rpi4*mm6108*spi*factory.img.gz" | sort | tail -n 1)"
    SYSUPGRADE_NAME="$(find "${TARGET_DIR}" -maxdepth 1 -type f -iname "*rpi4*mm6108*spi*sysupgrade.img.gz" | sort | tail -n 1)"
    MANIFEST_NAME="$(find "${TARGET_DIR}" -maxdepth 1 -type f -iname "*rpi4*mm6108*spi*.manifest" | sort | tail -n 1)"

    if [[ -z "${ARTIFACT_NAME}" ]]; then
        echo "Build completed, but the factory image for bcm2711_mm6108-spi was not found." >&2
        exit 1
    fi

    cp -f "${ARTIFACT_NAME}" /out/

    if [[ -n "${SYSUPGRADE_NAME}" ]]; then
        cp -f "${SYSUPGRADE_NAME}" /out/
    fi

    if [[ -n "${MANIFEST_NAME}" ]]; then
        cp -f "${MANIFEST_NAME}" /out/
    fi
'

echo
echo "Artifacts are available in: ${OUTPUT_DIR}"
find "${OUTPUT_DIR}" -maxdepth 1 -type f | sort
