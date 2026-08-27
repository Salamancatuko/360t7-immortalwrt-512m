#!/bin/bash
set -e
cd /root
rm -rf immortalwrt-mt798x
echo "=== cloning ==="
git clone --depth=1 -b openwrt-21.02 https://github.com/hanwckf/immortalwrt-mt798x.git immortalwrt-mt798x
cd immortalwrt-mt798x
echo "=== feeds update -a ==="
./scripts/feeds update -a
echo "=== feeds install -a ==="
./scripts/feeds install -a
echo "=== feeds dirs ==="
ls feeds/
echo "=== branch ==="
git branch --show-current
echo "=== DONE clone_feeds ==="
