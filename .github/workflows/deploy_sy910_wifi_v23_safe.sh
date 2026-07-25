#!/bin/bash
# SY910 WiFi Deployment Script v23 - SAFE MODE
# *** ONLY installs files, does NOT load modules ***
# *** v23: Dual compatible string + smart zip extraction ***
set -x
KVER=$(uname -r)

echo "=== SY910 WiFi UWE5621DS Deployment (v23 SAFE - install only) ==="
echo "Target kernel: $KVER"
echo ""
echo "*** This script ONLY installs files. It does NOT load modules. ***"
echo "*** You MUST reboot after this script, then load modules manually. ***"
echo ""

cd /tmp
rm -rf k
mkdir -p k
cd k

# 0. Pre-check: verify WiFi node exists in current device tree
echo "[0/7] Checking device tree for WiFi node..."
if [ -d /proc/device-tree ]; then
    UWE_NODE=$(find /proc/device-tree -name "uwe*" -type d 2>/dev/null | head -1)
    if [ -n "$UWE_NODE" ]; then
        echo "OK: WiFi DT node found: $UWE_NODE"
        COMPAT=$(cat "$UWE_NODE/compatible" 2>/dev/null)
        echo "  compatible = $COMPAT"
        # v23 driver supports BOTH "unisoc,uwe_bsp" and "unisoc,uwe-bsp"
        if echo "$COMPAT" | grep -q "unisoc,uwe"; then
            echo "  -> v23 driver will match this node (dual compatible support)"
        fi
    else
        echo "WARNING: No 'uwe*' node in device tree!"
        echo "WiFi module may not probe. Checking SDIO bus..."
        ls /sys/bus/mmc/devices/ 2>/dev/null
    fi
else
    echo "WARNING: /proc/device-tree not accessible"
fi
echo ""

# 1. Smart extraction - handles both single-zip and double-nested zip
echo "[1/7] Extracting modules (smart zip handling)..."
ZIP_FILE=""
for candidate in /tmp/rk3528-sy910-wifi-modules.zip /tmp/rk3528-sy910-wifi-modules*.zip; do
    if [ -f "$candidate" ]; then
        ZIP_FILE="$candidate"
        break
    fi
done

if [ -z "$ZIP_FILE" ]; then
    echo "ERROR: No rk3528-sy910-wifi-modules*.zip found in /tmp/!"
    echo "Please upload the compile artifact first."
    ls /tmp/*.zip 2>/dev/null
    exit 1
fi
echo "Using zip: $ZIP_FILE"

# First extraction
unzip -o "$ZIP_FILE" -d extract1

# Check if double-nested (zip inside zip)
INNER_ZIP=$(find extract1 -name "*.zip" -type f 2>/dev/null | head -1)
if [ -n "$INNER_ZIP" ]; then
    echo "Detected DOUBLE-NESTED zip! Extracting inner zip: $INNER_ZIP"
    unzip -o "$INNER_ZIP" -d extract2
    WORK_DIR="extract2"
else
    echo "Single-layer zip detected (v23 format)"
    WORK_DIR="extract1"
fi

echo "Contents of extracted archive:"
find "$WORK_DIR" -type f | sort | head -30
echo ""

# Locate .ko modules
BSP_KO=$(find "$WORK_DIR" -name "uwe5621_bsp_sdio.ko" 2>/dev/null | head -1)
WIFI_KO=$(find "$WORK_DIR" -name "sprdwl_ng.ko" 2>/dev/null | head -1)
if [ -z "$BSP_KO" ] || [ -z "$WIFI_KO" ]; then
    echo "ERROR: .ko modules not found in archive!"
    echo "Searched in: $WORK_DIR"
    find "$WORK_DIR" -name "*.ko" 2>/dev/null
    exit 1
fi
echo "BSP: $BSP_KO"
echo "WiFi: $WIFI_KO"

# 2. Install firmware
echo "[2/7] Installing firmware..."
# Check for firmware in archive first, then /tmp
FW_SRC=""
if [ -f "$WORK_DIR/wcnmodem.bin" ]; then
    FW_SRC="$WORK_DIR/wcnmodem.bin"
elif [ -f /tmp/wcnmodem.bin ]; then
    FW_SRC="/tmp/wcnmodem.bin"
fi

if [ -n "$FW_SRC" ]; then
    sudo cp "$FW_SRC" /lib/firmware/
    sudo chmod 644 /lib/firmware/wcnmodem.bin
    echo "wcnmodem.bin installed: $(ls -la /lib/firmware/wcnmodem.bin)"
else
    # Check if already exists from previous deployment
    if [ -f /lib/firmware/wcnmodem.bin ]; then
        echo "wcnmodem.bin already exists: $(ls -la /lib/firmware/wcnmodem.bin)"
    else
        echo "WARNING: wcnmodem.bin not found anywhere! WiFi needs this firmware!"
        echo "  Please upload wcnmodem.bin to /tmp/ and re-run, or copy manually:"
        echo "  sudo cp /tmp/wcnmodem.bin /lib/firmware/"
    fi
fi

# 3. Verify vermagic
echo "[3/7] Checking vermagic..."
BSP_VERMAGIC=$(modinfo "$BSP_KO" | grep vermagic)
WIFI_VERMAGIC=$(modinfo "$WIFI_KO" | grep vermagic)
echo "BSP:  $BSP_VERMAGIC"
echo "WiFi: $WIFI_VERMAGIC"
echo "Running kernel: $KVER"
if ! echo "$BSP_VERMAGIC" | grep -q "$KVER"; then
    echo "ERROR: BSP vermagic does not match running kernel!"
    echo "Do NOT proceed. Recompile with correct kernel version."
    exit 1
fi
echo "Vermagic OK"

# 4. Strip BTF if present (extra safety)
echo "[4/7] BTF check..."
if readelf -S "$BSP_KO" 2>/dev/null | grep -q ".BTF"; then
    echo "Stripping BTF from BSP..."
    sudo objcopy --remove-section=.BTF "$BSP_KO" 2>/dev/null || true
fi
if readelf -S "$WIFI_KO" 2>/dev/null | grep -q ".BTF"; then
    echo "Stripping BTF from WiFi..."
    sudo objcopy --remove-section=.BTF "$WIFI_KO" 2>/dev/null || true
fi
echo "BTF check done"

# 5. Install modules to system directory
echo "[5/7] Installing modules to /lib/modules/$KVER/..."
DST=/lib/modules/$KVER/kernel/drivers/net/wireless/unisoc
sudo mkdir -p $DST/unisocwcn $DST/unisocwifi
sudo cp "$BSP_KO" $DST/unisocwcn/
sudo cp "$WIFI_KO" $DST/unisocwifi/
sudo chmod 644 $DST/unisocwcn/uwe5621_bsp_sdio.ko
sudo chmod 644 $DST/unisocwifi/sprdwl_ng.ko
sudo depmod -a 2>/dev/null || true
echo "Modules installed:"
ls -la $DST/unisocwcn/ $DST/unisocwifi/

# 6. Create blacklist (prevent auto-load on reboot until manually verified)
echo "[6/7] Creating blacklist..."
sudo mkdir -p /etc/modprobe.d
echo "blacklist uwe5621_bsp_sdio" | sudo tee /etc/modprobe.d/blacklist-unisoc.conf
echo "blacklist sprdwl_ng" | sudo tee -a /etc/modprobe.d/blacklist-unisoc.conf
echo "Blacklist created:"
cat /etc/modprobe.d/blacklist-unisoc.conf

# 7. DTB policy
echo "[7/7] DTB policy check..."
# DTB update DISABLED - the original FnNAS DTB already has WiFi SDIO node
# (mmc1 detects SDIO card at address 8800 = proof DTB is correct)
# Replacing DTB with our compiled version BREAKS USB/network (DWC3 disabled)!
echo "[INFO] DTB update SKIPPED (original FnNAS DTB already has WiFi node)"
echo "[INFO] DO NOT replace the DTB - it will break USB and network!"
echo "[INFO] v23 driver supports BOTH compatible strings:"
echo "       - unisoc,uwe_bsp  (underscore, repo DTS)"
echo "       - unisoc,uwe-bsp  (hyphen, original FnNAS DTB)"

sync
echo ""
echo "=========================================="
echo "=== Installation complete (v23 SAFE) ==="
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. sudo reboot"
echo "  2. After reboot, SSH back in and run:"
echo ""
echo "     sudo modprobe uwe5621_bsp_sdio"
echo "     dmesg | tail -30"
echo "     # Check for: 'WCN: marlin_init entry!' and NO Oops/crash"
echo ""
echo "     sudo modprobe sprdwl_ng"
echo "     dmesg | tail -20"
echo "     ip link show | grep wlan"
echo ""
echo "  3. If WiFi works, remove blacklist for auto-load:"
echo "     sudo rm /etc/modprobe.d/blacklist-unisoc.conf"
echo ""
echo "  4. If crash occurs, capture: dmesg > /tmp/crash_v23.log"
echo "=========================================="
