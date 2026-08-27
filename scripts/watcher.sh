#!/bin/bash
cd /root/immortalwrt-mt798x
lastsize=-1
stable=0
for i in $(seq 1 900); do
  sz=$(stat -c%s /root/build_full.log 2>/dev/null || echo 0)
  alive=$(pgrep -fc "make -j10" 2>/dev/null || echo 0)
  if [ "$alive" = "0" ]; then
    if [ "$sz" = "$lastsize" ]; then
      stable=$((stable+1))
    else
      stable=0
    fi
    if [ "$stable" -ge 2 ]; then
      echo "=== build finished (no make proc, log stable) after ~$((i*60))s ==="
      break
    fi
  fi
  lastsize=$sz
  sleep 60
done
echo "=== last 100 lines of build log ==="
tail -100 /root/build_full.log
echo "=== error scan ==="
grep -iE "\berror\b|Error [0-9]+|failed|ERROR:" /root/build_full.log | tail -25 || echo "no errors found"
echo "=== target images dir ==="
ls -la bin/targets/mediatek/mt7981/ 2>/dev/null || echo "no images dir"
echo "=== WATCHER DONE ==="
