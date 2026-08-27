#!/bin/bash
set -e
cd /root/immortalwrt-mt798x
pkill -f "make -j10" 2>/dev/null || true
sleep 2
echo "=== fix ua3f Makefile: create luci dir before luasrc copy ==="
sed -i 's|\t$(CP) ./luasrc/\* $(1)/usr/lib/lua/luci/|\t$(INSTALL_DIR) $(1)/usr/lib/lua/luci\n\t$(CP) ./luasrc/* $(1)/usr/lib/lua/luci/|' package/ua3f/Makefile
grep -n -A1 "usr/lib/lua/luci" package/ua3f/Makefile
echo "=== verify ruby is still selected (openclash dep) ==="
grep -c "^CONFIG_PACKAGE_ruby=y" .config || echo 0
echo "=== resume build ==="
export FORCE_UNSAFE_CONFIGURE=1
nohup make -j10 V=s >> /root/build_full.log 2>&1 &
echo $! > /root/build.pid
sleep 5
echo "resumed pid $(cat /root/build.pid)"
pgrep -fc "make -j10" || echo "no make?"
