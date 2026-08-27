set -e
cd /root/immortalwrt-mt798x
echo "=== drop lmo install from ua3f Makefile ==="
sed -i '/i18n/d' package/ua3f/Makefile
grep -n "i18n" package/ua3f/Makefile || echo "i18n lines removed OK"
echo "=== test-compile sing-box ==="
make package/sing-box/compile V=s > /root/pkg-singbox.log 2>&1 && echo "sing-box OK" || { echo "sing-box FAIL"; tail -40 /root/pkg-singbox.log; exit 1; }
echo "=== test-compile ua3f ==="
make package/ua3f/compile V=s > /root/pkg-ua3f.log 2>&1 && echo "ua3f OK" || { echo "ua3f FAIL"; tail -40 /root/pkg-ua3f.log; exit 1; }
echo "=== test-compile luci-app-harbor-file ==="
make package/luci-app-harbor-file/compile V=s > /root/pkg-harbor.log 2>&1 && echo "harbor OK" || { echo "harbor FAIL"; tail -40 /root/pkg-harbor.log; exit 1; }
echo "=== test-compile luci-app-singbox-ui ==="
make package/luci-app-singbox-ui/compile V=s > /root/pkg-singboxui.log 2>&1 && echo "singboxui OK" || { echo "singboxui FAIL"; tail -40 /root/pkg-singboxui.log; exit 1; }
echo "=== test-compile luci-app-openclash ==="
make package/feeds/luci/luci-app-openclash/compile V=s > /root/pkg-openclash.log 2>&1 && echo "openclash OK" || { echo "openclash FAIL"; tail -40 /root/pkg-openclash.log; exit 1; }
echo "=== ipk outputs ==="
find bin -name "*.ipk" 2>/dev/null | grep -E "sing-box|ua3f|harbor|openclash" | head
echo "=== DONE test_compile ==="
