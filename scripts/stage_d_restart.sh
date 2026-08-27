#!/bin/bash
cd /root/immortalwrt-mt798x
pkill -f "make -j10" 2>/dev/null || true
sleep 2
export FORCE_UNSAFE_CONFIGURE=1
nohup make -j10 V=s >> /root/build_full.log 2>&1 &
echo $! > /root/build.pid
sleep 5
echo "restarted pid $(cat /root/build.pid)"
tail -3 /root/build_full.log
