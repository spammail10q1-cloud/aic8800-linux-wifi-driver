#!/usr/bin/env bash
# install.sh — Build and install the AIC8800 (AIC 8800D80) WiFi driver.
#
# Usage:
#   ./install.sh            # build + install (asks for sudo when needed)
#   sudo ./install.sh       # run as root
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

KVER="$(uname -r)"
KDIR="/lib/modules/${KVER}/build"

if [ ! -d "$KDIR" ]; then
    echo "ERROR: kernel headers not found at $KDIR"
    echo "Install them first, e.g.: sudo apt install linux-headers-${KVER} build-essential"
    exit 1
fi

# Ensure we have privileges for installation steps.
if [ "$(id -u)" -ne 0 ]; then
    echo "Re-running with sudo..."
    exec sudo bash "$0" "$@"
fi

echo "==> Building driver for kernel ${KVER}..."
make

echo "==> Installing kernel modules..."
mkdir -p "/lib/modules/${KVER}/kernel/drivers/net/wireless/aic8800"
install -p -m 644 drivers/aic8800/aic_load_fw/aic_load_fw.ko \
    "/lib/modules/${KVER}/kernel/drivers/net/wireless/aic8800/"
install -p -m 644 drivers/aic8800/aic8800_fdrv/aic8800_fdrv.ko \
    "/lib/modules/${KVER}/kernel/drivers/net/wireless/aic8800/"

echo "==> Installing firmware..."
mkdir -p /lib/firmware
cp -rf ./fw/aic8800D80 /lib/firmware/

echo "==> Installing udev rules..."
cp ./tools/aic.rules /etc/udev/rules.d/aic.rules
udevadm control --reload 2>/dev/null || true
udevadm trigger 2>/dev/null || true

# Auto-load on boot
echo "# AIC8800 WiFi driver modules - auto-load on boot" > /etc/modules-load.d/aic8800.conf
echo "aic_load_fw" >> /etc/modules-load.d/aic8800.conf
echo "aic8800_fdrv" >> /etc/modules-load.d/aic8800.conf

echo "==> Running depmod..."
depmod -a "${KVER}"

echo "==> Loading modules..."
modprobe cfg80211 2>/dev/null || true
modprobe aic_load_fw
modprobe aic8800_fdrv

echo
echo "Installation complete."
echo "A wireless interface should appear (check: ip link show / nmcli dev status)."
echo "If not, unplug and replug the dongle."