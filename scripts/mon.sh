#!/bin/bash
cd /root/immortalwrt-mt798x
PID=$(cat /root/build.pid 2>/dev/null)
if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
  echo "STATUS: RUNNING (pid $PID)"
else
  echo "STATUS: NOT RUNNING"
fi
echo "== last 15 lines =="
tail -15 /root/build_full.log 2>/dev/null
echo "== current stage =="
grep -oE "^(make\[[0-9]\])?:? ?(Entering|Leaving) directory|Compiling|Linking|Building (host )?toolchain|Preparing toolchain|Kernel|Generating" /root/build_full.log 2>/dev/null | tail -5
echo "== errors so far =="
grep -iE "error|failed|cannot|No such" /root/build_full.log 2>/dev/null | grep -v "WARNING" | tail -8
echo "== elapsed =="
ps -o etime= -p "$PID" 2>/dev/null || echo "n/a"
