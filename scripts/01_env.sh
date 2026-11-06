#!/bin/bash
# 01_env.sh - install build dependencies inside Debian 12 (run as root)
exec 2>&1
export DEBIAN_FRONTEND=noninteractive
set -o pipefail

echo "### host info"
. /etc/os-release; echo "$PRETTY_NAME  $(nproc) cores"

echo "### apt update"
apt-get update -qq || { echo "APT UPDATE FAILED"; exit 1; }

PKGS="build-essential gcc g++ gcc-multilib g++-multilib binutils make patch perl bzip2 unzip xz-utils
git subversion rsync wget curl file bc time openssl
autoconf automake autopoint libtool pkg-config libtool-bin
bison flex gperf gawk gettext texinfo help2man intltool
libncurses-dev libncursesw5-dev? libssl-dev zlib1g-dev libelf-dev libglib2.0-dev
libreadline-dev libgmp3-dev libmpc-dev libmpfr-dev libltdl-dev libyaml-dev
python3 python3-pip python3-setuptools python3-ply python3-docutils
swig device-tree-compiler cpio fastjar re2c scons squashfs-tools
cmake ninja-build ccache haveged upx-ucl p7zip-full
xmlto asciidoc lrzsz nano vim screen unzip zip xxd
screen rsync sudo ca-certificates tzdata locales"

INSTALL_LIST=""
for p in $PKGS; do
  case "$p" in *\?*) continue ;; esac
  INSTALL_LIST="$INSTALL_LIST $p"
done

echo "### installing core deps"
apt-get install -y -qq --no-install-recommends $INSTALL_LIST
rc=$?
echo "bulk install rc=$rc"

# retry individually for anything that blocked the bulk run
if [ $rc -ne 0 ]; then
  echo "### bulk install failed, retrying package by package"
  for p in $INSTALL_LIST; do
    apt-get install -y -qq --no-install-recommends "$p" >/dev/null 2>&1 \
      && echo "OK   $p" || echo "MISS $p"
  done
fi

echo "### extra packages (best effort)"
for p in ecj antlr3 mkisofs genisoimage libc6-dev-i386 qemu-utils msmtp uglifyjs node-uglify golang-go; do
  apt-get install -y -qq --no-install-recommends "$p" >/dev/null 2>&1 \
    && echo "OK   $p" || echo "skip $p"
done

echo "### tool versions"
for t in gcc g++ make python3 git perl rsync patch unzip bzip2 wget curl screen ccache dtc swig scons; do
  if command -v "$t" >/dev/null 2>&1; then
    printf '%-8s %s\n' "$t" "$("$t" --version 2>&1 | head -1)"
  else
    printf '%-8s MISSING\n' "$t"
  fi
done
python3 -c 'import pipes; print("pipes module OK")' 2>&1
python3 -c 'import distutils; print("distutils OK")' 2>&1
python3 -c 'import setuptools; print("setuptools OK")' 2>&1

echo "### build user"
id builder >/dev/null 2>&1 || useradd -m -s /bin/bash builder
echo 'builder ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/builder
chmod 440 /etc/sudoers.d/builder
echo "builder: $(id builder)"

echo "### disk"
df -h / | tail -1
echo "### DONE 01_env"
