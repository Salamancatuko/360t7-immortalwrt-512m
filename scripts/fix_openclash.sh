#!/bin/bash
set -e
cd /root/immortalwrt-mt798x
pkill -f "make -j10" 2>/dev/null || true
sleep 2

echo "=== 1. clone vernesong OpenClash master ==="
[ -d /root/pkgsrc/OpenClash ] || git clone --depth=1 https://github.com/vernesong/OpenClash.git /root/pkgsrc/OpenClash
echo "version:"
grep -E "PKG_VERSION" /root/pkgsrc/OpenClash/luci-app-openclash/Makefile | head -2
echo "deps (ruby check):"
grep -E "DEPENDS" /root/pkgsrc/OpenClash/luci-app-openclash/Makefile | grep -i ruby && echo "!!! ruby still present" || echo "no ruby dep (OK)"

echo "=== 2. remove feed openclash, copy vernesong version ==="
rm -rf feeds/luci/applications/luci-app-openclash
rm -f package/feeds/luci/luci-app-openclash
rm -rf package/luci-app-openclash
cp -r /root/pkgsrc/OpenClash/luci-app-openclash package/luci-app-openclash

echo "=== 3. regenerate feed index ==="
./scripts/feeds update -i

echo "=== 4. re-run defconfig (drop ruby) ==="
make defconfig > /root/defconfig2.log 2>&1 || { tail -30 /root/defconfig2.log; exit 1; }
echo "ruby selected? $(grep -c '^CONFIG_PACKAGE_ruby=y' .config || echo 0)"
grep -E "^CONFIG_PACKAGE_luci-app-openclash=y" .config && echo "openclash=y OK"

echo "=== 5. resume build ==="
export FORCE_UNSAFE_CONFIGURE=1
nohup make -j10 V=s >> /root/build_full.log 2>&1 &
echo $! > /root/build.pid
sleep 5
echo "resumed pid $(cat /root/build.pid)"
pgrep -fc "make -j10" || echo "no make?"
