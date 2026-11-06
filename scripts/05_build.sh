#!/bin/bash
# 05_build.sh - run the full build in the foreground of a background job
exec 2>&1
SRC=$HOME/immortalwrt
cd "$SRC" || exit 1
JOBS=$(nproc)
LOG=$HOME/build.log

[ -f .config ] || { echo "no .config"; exit 1; }
echo "### starting build: jobs=$JOBS start=$(date '+%F %T')"
: > "$LOG"
START=$(date +%s)
FORCE_UNSAFE_CONFIGURE=1 GOPROXY=https://goproxy.cn,direct GOSUMDB=off \
  make -j"$JOBS" V=s > "$LOG" 2>&1
RC=$?
END=$(date +%s)
echo "### make exited rc=$RC after $(( (END-START)/60 )) min"
echo "### last log lines:"
tail -30 "$LOG"
ls -lh "$SRC"/bin/targets/mediatek/mt7981/ 2>/dev/null
exit $RC
