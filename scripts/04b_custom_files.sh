#!/bin/bash
# 04b_custom_files.sh - rootfs overlay files + final config touch-ups
exec 2>&1
SRC=$HOME/immortalwrt
cd "$SRC" || exit 1

echo "### 1) fix ua3f postrm sledgehammer path"
sed -i 's|\[ -f "/etc/uci-defaults/../config/ucitrack" \]|[ -f "/etc/config/ucitrack" ]|' package/ua3f/Makefile
grep -n 'ucitrack' package/ua3f/Makefile

echo "### 2) rootfs overlay: default theme=argon, language=zh-cn"
mkdir -p files/etc/uci-defaults
cat > files/etc/uci-defaults/99-custom-defaults <<'EOF'
#!/bin/sh
# 360T7 custom image defaults: argon theme + simplified chinese UI
uci -q batch <<-EOT
	set luci.main.lang='zh-cn'
	set luci.main.mediaurlbase='/luci-static/argon'
	commit luci
EOT
exit 0
EOF
chmod +x files/etc/uci-defaults/99-custom-defaults
echo "-- overlay file:"
cat files/etc/uci-defaults/99-custom-defaults

echo "### 3) confirm argon theme dir name"
ls feeds/luci/themes/luci-theme-argon/htdocs/luci-static/ 2>/dev/null

echo "### 4) make defconfig"
make defconfig > /tmp/defconfig2.log 2>&1 || { echo "DEFCONFIG FAILED"; tail -30 /tmp/defconfig2.log; exit 1; }
tail -2 /tmp/defconfig2.log

echo "### 5) final selected apps/themes"
grep -E '^CONFIG_PACKAGE_luci-(app|theme)-[^_]*=y$' .config
echo "### 6) our three + argon"
grep -E '^CONFIG_PACKAGE_(ua3f|luci-app-openclash|luci-app-harbor-file|luci-app-argon-config|luci-theme-argon|luci-i18n-harbor-file-zh-cn|luci-i18n-argon-config-zh-cn)=y$' .config
echo "### 7) device"
grep -E '^CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_.*=y$' .config
echo "### 8) image type"
grep -E '^CONFIG_TARGET_ROOTFS_(SQUASHFS|EXT4|INITRAMFS)=' .config
echo "### DONE 04b"
