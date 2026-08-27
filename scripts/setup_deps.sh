#!/bin/bash
set -x
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
# 基础编译依赖（Debian 13 trixie 适用名称）
apt-get install -y \
  build-essential flex bison gcc-multilib g++-multilib \
  libncurses-dev zlib1g-dev libssl-dev libelf-dev libreadline-dev \
  libtool libtool-bin autoconf automake autopoint gettext gperf intltool \
  bzip2 xz-utils zstd unzip wget curl rsync file gawk patch cpio \
  python3 python3-pip python3-ply python3-docutils python3-setuptools \
  ccache cmake ninja-build swig subversion git \
  device-tree-compiler pkg-config qemu-utils squashfs-tools \
  haveged help2man p7zip p7zip-full tree jq
# 容错：逐个尝试可能缺失/可选包，失败不中断
for p in ack antlr3 asciidoc ecj fastjar mkisofs msmtp re2c scons texinfo uglifyjs upx-ucl xxd lld clang; do
  apt-get install -y "$p" >/dev/null 2>&1 || echo "skip $p"
done
echo "=== verify critical tools ==="
for c in gcc g++ make flex bison unzip wget curl python3 perl rsync file gawk getopt git zstd cpio patch gperf bzip2 xz ccache cmake; do
  if command -v "$c" >/dev/null 2>&1; then echo "OK  $c"; else echo "MISS $c"; fi
done
echo "=== done ==="
