# AIC8800 WiFi Driver (Linux)

Linux driver for the **AICSemi AIC8800** chipset family, including the **AIC 8800D80** USB WiFi 6 dongle (`a69c:8d83`).

This repository is a ready-to-use, GitHub-friendly copy of the driver with an `install.sh` script, firmware, udev rules, and a CI build workflow.

## Supported hardware (examples)

- AICSemi AIC 8800D80 — USB ID `a69c:8d83` (this dongle)
- Other AIC8800D80-based adapters (`a69c:5721`, `a69c:5723`, `a69c:5725`, …)
- AIC8800D81 / D41 / DC / DW variants (see `drivers/aic8800/aic8800_fdrv/aicwf_usb.h`)

## Requirements

```bash
# Debian/Ubuntu/Zorin
sudo apt install linux-headers-$(uname -r) build-essential git

# Fedora
sudo dnf install kernel-devel kernel-headers gcc make git
```

## Quick start

```bash
git clone https://github.com/<you>/wifi-driver.git
cd wifi-driver
./install.sh
```

The script builds the modules, installs firmware to `/lib/firmware/aic8800D80`,
installs udev rules, configures auto-load on boot, and loads the driver.

After installation, check the interface:

```bash
ip link show
nmcli dev status
nmcli dev wifi list
```

If no WiFi device appears, unplug and replug the dongle.

## Uninstall

```bash
sudo ./uninstall.sh
```

## DKMS (optional)

A `dkms.conf` is included. To use DKMS, copy the tree to `/usr/src/aic8800-1.0`
and run `dkms add/build/install` (see original instructions in `install_setup.sh`).

## Kernel compatibility

Tested/built against kernels 3.x through 7.1.x. Version-specific differences are
handled internally via `LINUX_VERSION_CODE` guards.

## License

MIT License (see `LICENSE`). Original driver by goecho/asanrivas; based on
AICSemi reference driver.