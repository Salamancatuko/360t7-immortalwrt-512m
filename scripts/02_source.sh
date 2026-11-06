#!/bin/bash
# 02_source.sh - clone source tree + feeds (run as builder)
exec 2>&1
set -o pipefail
SRC=$HOME/immortalwrt

echo "### whoami: $(whoami)  home=$HOME"

if [ -d "$SRC/.git" ]; then
  echo "### source already present"
else
  echo "### cloning hanwckf/immortalwrt-mt798x (openwrt-21.02)"
  git clone --depth=1 -b openwrt-21.02 https://github.com/hanwckf/immortalwrt-mt798x.git "$SRC" || {
    echo "CLONE FAILED"; exit 1; }
fi

cd "$SRC"
echo "### branch: $(git branch --show-current)  commit: $(git rev-parse --short HEAD)"
echo "### feeds.conf.default"
cat feeds.conf.default

echo "### feeds update -a"
./scripts/feeds update -a || { echo "FEEDS UPDATE FAILED"; exit 1; }
echo "### feeds install -a"
./scripts/feeds install -a || { echo "FEEDS INSTALL FAILED"; exit 1; }

echo "### feeds dirs"
ls feeds/
echo "### package count"
find package feeds -maxdepth 3 -name Makefile 2>/dev/null | wc -l

echo "### wifi driver candidates in tree"
grep -rl "mt7915e" package/kernel/ 2>/dev/null | head
ls package/kernel/mt76 2>/dev/null | head -20
echo "### mt76 driver names"
grep -oE "KernelPackage/[a-zA-Z0-9_-]+" package/kernel/mt76/Makefile 2>/dev/null | sort -u | head -30

echo "### DONE 02_source"
