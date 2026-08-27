#!/bin/bash
set -e
cd /root/immortalwrt-mt798x
pkill -f "make -j10" 2>/dev/null || true
sleep 2
echo "=== unset ruby in .config ==="
sed -i -E 's/^(CONFIG_PACKAGE_ruby(-[^=]*)?)=y$/# \1 is not set/' .config
grep -c "^CONFIG_PACKAGE_ruby=y" .config || echo "0 direct"
make defconfig > /root/defconfig3.log 2>&1 || { tail -30 /root/defconfig3.log; exit 1; }
echo "ruby selected now: $(grep -c '^CONFIG_PACKAGE_ruby=y' .config || echo 0)"
echo "== our 5 packages =="
grep -E "^CONFIG_PACKAGE_(luci-app-openclash|sing-box|ua3f|luci-app-harbor-file|luci-app-singbox-ui)=y" .config
echo "== resume build =="
export FORCE_UNSAFE_CONFIGURE=1
nohup make -j10 V=s >> /root/build_full.log 2>&1 &
echo $! > /root/build.pid
sleep 5
echo "resumed pid $(cat /root/build.pid)"
