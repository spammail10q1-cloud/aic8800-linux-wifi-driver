#!/usr/bin/env bash
set -euo pipefail
KVER="$(uname -r)"
if [ "$(id -u)" -ne 0 ]; then
    exec sudo bash "$0" "$@"
fi
rmmod aic8800_fdrv 2>/dev/null || true
rmmod aic_load_fw 2>/dev/null || true
rm -f "/lib/modules/${KVER}/kernel/drivers/net/wireless/aic8800/aic8800_fdrv.ko"
rm -f "/lib/modules/${KVER}/kernel/drivers/net/wireless/aic8800/aic_load_fw.ko"
rmdir "/lib/modules/${KVER}/kernel/drivers/net/wireless/aic8800" 2>/dev/null || true
rm -rf /lib/firmware/aic8800D80
rm -f /etc/udev/rules.d/aic.rules
rm -f /etc/modules-load.d/aic8800.conf
depmod -a "${KVER}"
echo "Uninstalled."