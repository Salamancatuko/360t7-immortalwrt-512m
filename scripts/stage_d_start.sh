#!/bin/bash
cd /root/immortalwrt-mt798x
if [ -f /root/build.pid ] && kill -0 "$(cat /root/build.pid)" 2>/dev/null; then
  echo "build already running pid $(cat /root/build.pid)"
  exit 0
fi
rm -f /root/build_full.log
nohup make -j10 V=s > /root/build_full.log 2>&1 &
echo $! > /root/build.pid
sleep 3
echo "build started pid $(cat /root/build.pid)"
tail -3 /root/build_full.log
