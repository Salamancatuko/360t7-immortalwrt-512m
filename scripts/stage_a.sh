#!/bin/bash
set -e
export PATH=/root/go1.24.7/bin:$PATH
export GOTOOLCHAIN=local
export GOPROXY=https://goproxy.cn,direct

mkdir -p /root/prebuilt /root/pkgsrc
cd /root/pkgsrc

echo "=== 1. Go toolchain ==="
if [ ! -x /root/go1.24.7/bin/go ]; then
  cd /tmp
  rm -f go1.24.7.linux-amd64.tar.gz
  echo "-- mirrors.aliyun.com --"
  curl -fL --retry 3 --connect-timeout 20 --max-time 900 -o go1.24.7.linux-amd64.tar.gz \
    https://mirrors.aliyun.com/golang/go1.24.7.linux-amd64.tar.gz || {
    echo "-- golang.google.cn --"
    curl -fL --retry 3 --connect-timeout 20 --max-time 900 -o go1.24.7.linux-amd64.tar.gz \
      https://golang.google.cn/dl/go1.24.7.linux-amd64.tar.gz
  }
  sz=$(stat -c%s go1.24.7.linux-amd64.tar.gz)
  echo "tarball size: $sz"
  [ "$sz" -gt 50000000 ] || { echo "tarball too small"; exit 1; }
  tar -C /root -xzf go1.24.7.linux-amd64.tar.gz
  mv /root/go /root/go1.24.7
fi
/root/go1.24.7/bin/go version

echo "=== 2. sources ==="
cd /root/pkgsrc
[ -d sing-box-src ] || git clone --depth=1 -b v1.13.19 https://github.com/SagerNet/sing-box.git sing-box-src
[ -d ua3f-src ] || git clone --depth=1 https://github.com/SunBK201/UA3F.git ua3f-src
[ -d small-package ] || git clone --depth=1 https://github.com/kenzok8/small-package.git small-package
[ -d luci-app-harbor-file ] || git clone --depth=1 https://github.com/destan19/luci-app-harbor-file.git
[ -d luci-app-singbox-ui ] || git clone --depth=1 https://github.com/ang3el7z/luci-app-singbox-ui.git
echo "clones done"

echo "=== 3. cross-compile sing-box (arm64, full tags) ==="
cd /root/pkgsrc/sing-box-src
GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -trimpath \
  -ldflags "-s -w -X github.com/sagernet/sing-box/constant.Version=1.13.19" \
  -tags "with_acme,with_clash_api,with_dhcp,with_gvisor,with_quic,with_tailscale,with_utls,with_wireguard" \
  -o /root/prebuilt/sing-box ./cmd/sing-box

echo "=== 4. cross-compile ua3f (arm64) ==="
cd /root/pkgsrc/ua3f-src
GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -trimpath \
  -ldflags "-s -w -X main.appVersion=v3.6.0" \
  -o /root/prebuilt/ua3f .

echo "=== 5. verify ==="
file /root/prebuilt/sing-box /root/prebuilt/ua3f
ls -la /root/prebuilt/
echo "=== DONE stage_a ==="
