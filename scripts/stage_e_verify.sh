#!/bin/bash
cd /root/immortalwrt-mt798x
echo "=== 1. images ==="
ls -la bin/targets/mediatek/mt7981/ 2>/dev/null
echo
echo "=== 2. sha256 of images ==="
sha256sum bin/targets/mediatek/mt7981/*.bin 2>/dev/null
echo
echo "=== 3. our packages built? ==="
find bin -name "*.ipk" 2>/dev/null | grep -E "sing-box|ua3f|harbor|openclash|singbox-ui"
echo
echo "=== 4. filebrowser ipk built? (should be empty) ==="
find bin -name "*filebrowser*" 2>/dev/null || echo "none (OK)"
echo
echo "=== 5. package list inside rootfs manifest ==="
find bin -name "*.manifest" 2>/dev/null | head -3
M=$(find bin -name "*.manifest" 2>/dev/null | head -1)
if [ -n "$M" ]; then
  echo "--- our 5 packages in manifest ---"
  grep -E "^(sing-box|ua3f|luci-app-harbor-file|luci-app-openclash|luci-app-singbox-ui) " "$M"
  echo "--- filebrowser in manifest? ---"
  grep -c "filebrowser" "$M" || echo "0 (OK)"
  echo "--- total packages ---"
  wc -l < "$M"
fi
echo
echo "=== 6. image size vs 110592k ==="
for f in bin/targets/mediatek/mt7981/*-sysupgrade.bin bin/targets/mediatek/mt7981/*-factory.bin; do
  [ -f "$f" ] && echo "$(stat -c%s "$f") bytes  $f"
done
echo "=== DONE stage_e ==="
