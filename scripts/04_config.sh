#!/bin/bash
# 04_config.sh - build .config: single device, open mt76 wifi, only argon + 3 added apps
exec 2>&1
set -o pipefail
SRC=$HOME/immortalwrt
cd "$SRC" || exit 1

cp -f defconfig/mt7981-ax3000.config .config

echo "### 1) keep only mt7981-360-t7-108M device"
sed -i -E 's/^(CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_[^=]*)=y$/# \1 is not set/' .config
sed -i -E 's/^(CONFIG_TARGET_DEVICE_PACKAGES_mediatek_mt7981_DEVICE_[^=]*)=.*$/# \1 is not set/' .config
sed -i 's/^# CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_mt7981-360-t7-108M is not set$/CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_mt7981-360-t7-108M=y/' .config
echo "CONFIG_TARGET_DEVICE_PACKAGES_mediatek_mt7981_DEVICE_mt7981-360-t7-108M=\"\"" >> .config

echo "### 2) strip optional LuCI plugins / clutter (keep MTK wifi driver chain)"
STRIP="
luci-app-eqos-mtk luci-app-mtwifi-cfg luci-app-turboacc-mtk luci-app-upnp
luci-i18n-eqos-mtk-zh-cn luci-i18n-mtwifi-cfg-zh-cn luci-i18n-turboacc-mtk-zh-cn luci-i18n-upnp-zh-cn
luci-theme-bootstrap-mod
nano tcpdump htop openssl-util openssh-keygen openssh-sftp-server
kvcedit libkvcutil mii_mgr mtkhqos_util regs
tc-mod-iptables tc-tiny
miniupnpd
kmod-zram zram-swap
ethtool wireless-tools
libcap-ng libcbor libevdev libfido2 libudev-zero
"
for p in $STRIP; do
  sed -i -E "s/^CONFIG_PACKAGE_${p}=y$/# CONFIG_PACKAGE_${p} is not set/" .config
done
sed -i -E 's/^CONFIG_PACKAGE_TURBOACC_.*$/# &/' .config
sed -i -E 's/^CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_.*$/# &/' .config
sed -i -E 's/^CONFIG_PACKAGE_luci-app-passwall_INCLUDE_.*$/# &/' .config
sed -i -E 's/^CONFIG_PACKAGE_luci-app-vssr_INCLUDE_.*$/# &/' .config
sed -i -E 's/^CONFIG_PACKAGE_luci-app-rclone_INCLUDE_.*$/# &/' .config

echo "### 3) enable what we want"
cat >> .config <<'EOF'
# --- base web UI (zh-cn) ---
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-compat=y
CONFIG_PACKAGE_luci-ssl-openssl=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
# --- theme: argon only ---
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-app-argon-config=y
CONFIG_PACKAGE_luci-i18n-argon-config-zh-cn=y
# --- wifi: MTK closed driver + mtwifi-cfg netifd layer (no LuCI plugin) ---
CONFIG_PACKAGE_kmod-mt_wifi=y
CONFIG_PACKAGE_wifi-dats=y
CONFIG_PACKAGE_mtwifi-cfg=y
CONFIG_PACKAGE_kmod-warp=y
CONFIG_PACKAGE_iwinfo=y
# --- switch support for LuCI network page ---
CONFIG_PACKAGE_swconfig=y
CONFIG_PACKAGE_wireless-regdb=y
# --- added apps ---
CONFIG_PACKAGE_ua3f=y
CONFIG_PACKAGE_luci-app-openclash=y
CONFIG_PACKAGE_luci-app-harbor-file=y
CONFIG_PACKAGE_luci-i18n-harbor-file-zh-cn=y
EOF

echo "### 4) make defconfig"
make defconfig > /tmp/defconfig.log 2>&1 || { echo "DEFCONFIG FAILED"; tail -40 /tmp/defconfig.log; exit 1; }
tail -3 /tmp/defconfig.log

echo "### 5) verification"
echo "== devices enabled =="
grep -E '^CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_.*=y$' .config
echo "== wifi driver =="
grep -E '^CONFIG_PACKAGE_(kmod-mt7915e|kmod-mt_wifi|wpad|kmod-mt7915-firmware)' .config
echo "== luci apps selected (must be argon-config/openclash/harbor-file only) =="
grep -E '^CONFIG_PACKAGE_luci-app-[^_]*=y$' .config
echo "== themes =="
grep -E '^CONFIG_PACKAGE_luci-theme-.*=y$' .config
echo "== our packages =="
grep -E '^CONFIG_PACKAGE_(ua3f|luci-app-openclash|luci-app-harbor-file|luci-i18n-harbor-file-zh-cn|luci-app-argon-config|luci-i18n-argon-config-zh-cn|luci|luci-i18n-base-zh-cn|swconfig)=' .config
echo "== residual strip check (should print nothing) =="
grep -E '^CONFIG_PACKAGE_(luci-app-eqos-mtk|luci-app-mtwifi-cfg|luci-app-turboacc-mtk|luci-app-upnp|kmod-mt_wifi|wifi-dats|mtwifi-cfg|nano|tcpdump|zram-swap|regs|mii_mgr|kvcedit)=' .config
echo "== dnsmasq =="
grep -E '^CONFIG_PACKAGE_dnsmasq' .config
echo "== apk/opkg =="
grep -E '^CONFIG_(PER_DEVICE_ROOTFS|SIGNED_PACKAGES|TARGET_ROOTFS)' .config | head
echo "### DONE 04_config"
