#!/bin/bash
exec 2>&1
OUT=$HOME/immortalwrt/bin/targets/mediatek/mt7981
DEST=/mnt/c/Users/Salam/Documents/deepseek/firmware/360t7-512mb-v2
SRC=$HOME/immortalwrt
mkdir -p "$DEST"
cp -f "$OUT"/profiles.json "$DEST"/
cd "$DEST" && sha256sum -c sha256sums 2>&1 | tail -3

echo
echo "### build reproducibility bundle"
cd "$SRC" || exit 1
git diff > "$DEST"/patches-01-dts-512mb.patch
echo "-- tracked changes:"
git status --porcelain | head -20
TAR=$DEST/customizations.tar.gz
tar -czf "$TAR" \
  --exclude='package/ua3f/src' \
  package/ua3f package/luci-app-openclash package/luci-app-harbor-file files 2>/dev/null
ls -lh "$TAR"
echo
echo "### delivery dir"
ls -lh "$DEST"
echo
echo "### manifest summary"
echo "-- total packages: $(grep -c '' "$OUT"/immortalwrt-mediatek-mt7981.manifest)"
echo "-- luci apps installed:"
grep -oE '^luci-app-[^ ]+' "$OUT"/immortalwrt-mediatek-mt7981.manifest | tr '\n' ' '
echo
echo "-- themes:"
grep -oE '^luci-theme-[^ ]+' "$OUT"/immortalwrt-mediatek-mt7981.manifest | tr '\n' ' '
echo
echo "-- our adds:"
grep -E '^(ua3f|luci-app-openclash|luci-app-harbor-file|luci-app-argon-config|luci-theme-argon) ' "$OUT"/immortalwrt-mediatek-mt7981.manifest
