#!/bin/bash
# 06_verify.sh - verify build artifacts
exec 2>&1
SRC=$HOME/immortalwrt
cd "$SRC" || exit 1
OUT=$SRC/bin/targets/mediatek/mt7981

echo "### 1) artifacts"
ls -lh "$OUT" 2>/dev/null || { echo "NO OUTPUT DIR"; exit 1; }
echo
echo "### 2) sha256"
cat "$OUT/sha256sums" 2>/dev/null

echo
echo "### 3) dtb memory size (must be 0x20000000 = 512MB)"
DTB=$(find build_dir -name 'image-mt7981-360-t7-108M.dtb' 2>/dev/null | head -1)
echo "dtb: $DTB"
if [ -n "$DTB" ]; then
  dtc -I dtb -O dts "$DTB" 2>/dev/null | grep -A3 'memory@40000000' | head -8
fi

echo
echo "### 4) package manifest - required present"
MAN=$(ls "$OUT"/../..//targets/mediatek/mt7981/*.manifest 2>/dev/null | head -1)
MAN=$(ls -t "$OUT"/*.manifest 2>/dev/null | head -1)
echo "manifest: $MAN"
for p in ua3f luci-app-openclash luci-app-harbor-file luci-i18n-harbor-file-zh-cn \
         luci-app-argon-config luci-theme-argon luci luci-i18n-base-zh-cn \
         kmod-mt7915e wpad dnsmasq-full ruby; do
  if grep -q "^$p " "$MAN" 2>/dev/null; then echo "OK      $p"; else echo "MISSING $p"; fi
done

echo
echo "### 5) package manifest - must be ABSENT"
for p in luci-app-eqos-mtk luci-app-mtwifi-cfg luci-app-turboacc-mtk luci-app-upnp \
         luci-theme-bootstrap-mod kmod-mt_wifi wifi-dats mtwifi-cfg nano tcpdump \
         zram-swap mii_mgr kvcedit regs turboacc sing-box luci-app-singbox-ui; do
  if grep -q "^$p " "$MAN" 2>/dev/null; then echo "PRESENT! $p"; else echo "ok absent $p"; fi
done

echo
echo "### 6) package count"
wc -l < "$MAN"

echo
echo "### 7) image sizes / limits"
for f in "$OUT"/*.bin; do
  [ -f "$f" ] && printf '%-70s %8s MB\n' "$(basename "$f")" "$(echo "scale=1; $(stat -c%s "$f")/1048576" | bc)"
done

echo "### DONE 06_verify"
