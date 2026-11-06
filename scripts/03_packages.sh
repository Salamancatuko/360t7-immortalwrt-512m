#!/bin/bash
# 03_packages.sh - DTS 512MB patch + UA3F / OpenClash / harbor-file integration (run as builder)
exec 2>&1
set -o pipefail
SRC=$HOME/immortalwrt
PKGSRC=$HOME/pkgsrc
PRE=$HOME/prebuilt
export PATH=$HOME/go/bin:$PATH
export GOTOOLCHAIN=local
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=off

cd "$SRC" || { echo "NO SOURCE TREE"; exit 1; }
mkdir -p "$PKGSRC" "$PRE"

#############################
echo "### 1) DTS 512MB memory"
DTS=target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/mt7981-360-t7-base.dtsi
if [ -f "$DTS" ]; then
  sed -i 's/reg = <0 0x40000000 0 0x10000000>;/reg = <0 0x40000000 0 0x20000000>;/' "$DTS"
  echo "-- memory node now:"
  grep -n -A2 'memory {' "$DTS" | head -6
else
  echo "!! DTS NOT FOUND: $DTS"; find target/linux/mediatek -name 'mt7981-360-t7*' | head
fi

#############################
echo "### 2) Go toolchain (host, for cross-compiling UA3F)"
if [ ! -x "$HOME/go/bin/go" ]; then
  cd /tmp
  GOVER=1.24.7
  ok=0
  for url in \
    "https://mirrors.aliyun.com/golang/go${GOVER}.linux-amd64.tar.gz" \
    "https://golang.google.cn/dl/go${GOVER}.linux-amd64.tar.gz" \
    "https://go.dev/dl/go${GOVER}.linux-amd64.tar.gz" ; do
    echo "-- trying $url"
    if curl -fL --retry 2 --connect-timeout 25 --max-time 900 -o go.tgz "$url"; then
      sz=$(stat -c%s go.tgz)
      if [ "$sz" -gt 50000000 ]; then ok=1; break; fi
    fi
  done
  [ $ok -eq 1 ] || { echo "GO DOWNLOAD FAILED"; exit 1; }
  rm -rf "$HOME/go"
  tar -C "$HOME" -xzf go.tgz
fi
"$HOME/go/bin/go" version

#############################
echo "### 3) clone plugin sources"
cd "$PKGSRC"
clone() { [ -d "$2/.git" ] || git clone --depth=1 ${3:+-b "$3"} "$1" "$2" || return 1; }
clone https://github.com/SunBK201/UA3F.git ua3f-src || echo "WARN ua3f clone"
clone https://github.com/vernesong/OpenClash.git OpenClash || echo "WARN openclash clone"
clone https://github.com/destan19/luci-app-harbor-file.git luci-app-harbor-file || echo "WARN harbor-file clone"

echo "-- UA3F layout:"
find ua3f-src/openwrt -maxdepth 2 2>/dev/null | head -40
echo "-- UA3F version:"
git -C ua3f-src describe --tags --abbrev=0 2>/dev/null || echo "no tag"
echo "-- OpenClash Makefile head:"
sed -n '1,40p' OpenClash/luci-app-openclash/Makefile 2>/dev/null
echo "-- OpenClash DEPENDS:"
grep -n "DEPENDS" OpenClash/luci-app-openclash/Makefile 2>/dev/null
echo "-- harbor-file layout:"
find luci-app-harbor-file -maxdepth 3 -name Makefile -o -maxdepth 2 -type d | head -30

#############################
echo "### 4) cross-compile UA3F for arm64"
cd "$PKGSRC/ua3f-src"
UA3F_VER=$(sed -n 's/^PKG_VERSION:=\([0-9.]*\).*/\1/p' "$PKGSRC/ua3f-src/openwrt/Makefile" 2>/dev/null)
[ -n "$UA3F_VER" ] || UA3F_VER=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//')
UA3F_VER=${UA3F_VER:-3.7.0}
echo "UA3F_VER=$UA3F_VER"
GOOS=linux GOARCH=arm64 CGO_ENABLED=0 "$HOME/go/bin/go" build -trimpath \
  -ldflags "-s -w -X main.appVersion=v${UA3F_VER}" -o "$PRE/ua3f" . || {
  echo "UA3F BUILD FAILED"; exit 1; }
file "$PRE/ua3f"; ls -l "$PRE/ua3f"

#############################
echo "### 5) ua3f openwrt package"
cd "$SRC" || { echo "NO SOURCE TREE"; exit 1; }
rm -rf "$PKGSRC/package"
UA=$PKGSRC/ua3f-src/openwrt
rm -rf package/ua3f
mkdir -p package/ua3f/src package/ua3f/files package/ua3f/luasrc package/ua3f/htdocs
cp "$PRE/ua3f" package/ua3f/src/ua3f
for f in ua3f.conf ua3f.init uci-defaults; do
  [ -f "$UA/files/$f" ] && cp "$UA/files/$f" package/ua3f/files/ || echo "WARN missing $f"
done
[ -d "$UA/luasrc" ] && cp -r "$UA/luasrc/." package/ua3f/luasrc/ || echo "WARN no luasrc"
[ -d "$UA/htdocs" ] && cp -r "$UA/htdocs/." package/ua3f/htdocs/ || echo "WARN no htdocs"

# host po2lmo: build from the copy bundled with OpenClash and install into PATH
echo "-- building host po2lmo"
P2=$PKGSRC/OpenClash/luci-app-openclash/tools/po2lmo
if [ -f "$P2/Makefile" ]; then
  make -C "$P2" clean >/dev/null 2>&1
  make -C "$P2" >/dev/null 2>&1 && sudo make -C "$P2" install >/dev/null 2>&1 && echo "po2lmo installed to /usr/bin"
fi
if [ ! -x /usr/bin/po2lmo ]; then
  SRC2=$(find "$SRC/feeds/luci" -name po2lmo.c 2>/dev/null | head -1)
  [ -n "$SRC2" ] && gcc -O2 -o /tmp/po2lmo "$SRC2" "$(dirname "$SRC2")/template_lmo.c" && sudo install -m755 /tmp/po2lmo /usr/bin/po2lmo
fi
PO2LMO=$(command -v po2lmo || true)
echo "po2lmo: ${PO2LMO:-NOT FOUND}"
[ -x "$PO2LMO" ] || { echo "!! po2lmo MISSING - openclash build will fail"; }
UA_PO=$(find "$UA/po" -name 'ua3f.po' 2>/dev/null | head -1)
echo "ua3f.po: ${UA_PO:-none}"
LMO_LINE=""
if [ -x "$PO2LMO" ] && [ -n "$UA_PO" ]; then
  "$PO2LMO" "$UA_PO" package/ua3f/files/ua3f.zh-cn.lmo && echo "lmo OK"
  LMO_LINE='	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) ./files/ua3f.zh-cn.lmo $(1)/usr/lib/lua/luci/i18n/ua3f.zh-cn.lmo'
fi

cat > package/ua3f/Makefile <<EOF
include \$(TOPDIR)/rules.mk

PKG_NAME:=ua3f
PKG_VERSION:=$UA3F_VER
PKG_RELEASE:=1

PKG_MAINTAINER:=SunBK201 <sunbk201gm@gmail.com>
PKG_LICENSE:=GPL-3.0-only

PKG_BUILD_DIR:=\$(BUILD_DIR)/\$(PKG_NAME)-\$(PKG_VERSION)
PKG_BUILD_PARALLEL:=1

include \$(INCLUDE_DIR)/package.mk

define Package/ua3f
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=Advanced HTTP Rewriting Proxy (UA3F, with LuCI)
  URL:=https://github.com/SunBK201/UA3F
  DEPENDS:=+luci-compat +libpcre2 +ipset +iptables +iptables-mod-tproxy +iptables-mod-extra \
	+iptables-mod-ipopt +iptables-mod-nfqueue +iptables-mod-conntrack-extra +kmod-nf-conntrack-netlink
endef

define Package/ua3f/description
  UA3F (Ultimate Advanced URL Filter) HTTP rewriting proxy. Prebuilt aarch64
  binary cross-compiled with Go; LuCI pages and zh-cn translation included.
endef

define Package/ua3f/conffiles
/etc/config/ua3f
endef

define Build/Prepare
	\$(INSTALL_DIR) \$(PKG_BUILD_DIR)
	\$(CP) ./src/ua3f \$(PKG_BUILD_DIR)/ua3f
endef

define Build/Compile
endef

define Package/ua3f/install
	\$(INSTALL_DIR) \$(1)/usr/bin
	\$(INSTALL_BIN) \$(PKG_BUILD_DIR)/ua3f \$(1)/usr/bin/ua3f
	\$(INSTALL_DIR) \$(1)/etc/config
	\$(INSTALL_CONF) ./files/ua3f.conf \$(1)/etc/config/ua3f
	\$(INSTALL_DIR) \$(1)/etc/init.d
	\$(INSTALL_BIN) ./files/ua3f.init \$(1)/etc/init.d/ua3f
	\$(INSTALL_DIR) \$(1)/etc/uci-defaults
	\$(INSTALL_BIN) ./files/uci-defaults \$(1)/etc/uci-defaults/luci-ua3f
	\$(INSTALL_DIR) \$(1)/usr/lib/lua/luci
	\$(CP) ./luasrc/* \$(1)/usr/lib/lua/luci/
	\$(CP) ./htdocs/* \$(1)/
$LMO_LINE
endef

define Package/ua3f/postrm
#!/bin/sh
uci -q set ua3f.enabled.enabled=0
uci -q commit ua3f
[ -f "/etc/uci-defaults/../config/ucitrack" ] && {
	uci -q delete ucitrack.ua3f
	uci -q commit ucitrack
}
endef

\$(eval \$(call BuildPackage,ua3f))
EOF
echo "-- ua3f package files:"; find package/ua3f -type f | head -20

#############################
echo "### 6) luci-app-harbor-file"
rm -rf package/luci-app-harbor-file
cp -r "$PKGSRC/luci-app-harbor-file" package/luci-app-harbor-file
rm -rf package/luci-app-harbor-file/.git
echo "-- files:"; ls package/luci-app-harbor-file
echo "-- Makefile:"; sed -n '1,40p' package/luci-app-harbor-file/Makefile 2>/dev/null

#############################
echo "### 7) luci-app-openclash (vernesong master)"
rm -rf feeds/luci/applications/luci-app-openclash
rm -f package/feeds/luci/luci-app-openclash
rm -rf package/luci-app-openclash
cp -r "$PKGSRC/OpenClash/luci-app-openclash" package/luci-app-openclash
rm -rf package/luci-app-openclash/.git
echo "-- Makefile:"; sed -n '1,45p' package/luci-app-openclash/Makefile

echo "### DONE 03_packages"
