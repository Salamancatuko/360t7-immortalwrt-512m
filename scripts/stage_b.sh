#!/bin/bash
set -e
cd /root/immortalwrt-mt798x

echo "=== 0. preconditions ==="
ls -la /root/prebuilt/sing-box /root/prebuilt/ua3f || { echo "stage A artifacts missing"; exit 1; }

echo "=== 1. 512MB memory fix ==="
DTS=target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/mt7981-360-t7-base.dtsi
sed -i 's/reg = <0 0x40000000 0 0x10000000>/reg = <0 0x40000000 0 0x20000000>/' "$DTS"
grep -n -A2 "memory" "$DTS" | head -6

echo "=== 2. luci-app-harbor-file ==="
rm -rf package/luci-app-harbor-file
cp -r /root/pkgsrc/luci-app-harbor-file package/luci-app-harbor-file
ls package/luci-app-harbor-file/

echo "=== 3. luci-app-singbox-ui ==="
rm -rf package/luci-app-singbox-ui
cp -r /root/pkgsrc/luci-app-singbox-ui/luci-app-singbox-ui package/luci-app-singbox-ui
ls package/luci-app-singbox-ui/ | head

echo "=== 4. sing-box package (prebuilt) ==="
rm -rf package/sing-box
mkdir -p package/sing-box/src package/sing-box/files
cp /root/prebuilt/sing-box package/sing-box/src/sing-box
# init script: prefer small-package's; fallback to minimal procd
if [ -s /root/pkgsrc/small-package/sing-box/files/sing-box.init ]; then
  cp /root/pkgsrc/small-package/sing-box/files/sing-box.init package/sing-box/files/sing-box.init
else
  cat > package/sing-box/files/sing-box.init <<'EOF'
#!/bin/sh /etc/rc.common
USE_PROCD=1
START=99
STOP=10
PROG=/usr/bin/sing-box
CONF=/etc/sing-box/config.json

start_service() {
	[ -f "$CONF" ] || return 0
	procd_open_instance
	procd_set_param command "$PROG" run -c "$CONF"
	procd_set_param respawn 3600 5 5
	procd_set_param user root
	procd_close_instance
}
EOF
  chmod +x package/sing-box/files/sing-box.init
fi
cp /root/pkgsrc/small-package/sing-box/files/sing-box.conf package/sing-box/files/sing-box.conf
cat > package/sing-box/Makefile <<'EOF'
include $(TOPDIR)/rules.mk

PKG_NAME:=sing-box
PKG_VERSION:=1.13.19
PKG_RELEASE:=1

PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>
PKG_LICENSE:=GPL-3.0-or-later

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/sing-box
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=The universal proxy platform (full, prebuilt)
  URL:=https://sing-box.sagernet.org/
  DEPENDS:=+ca-bundle +kmod-inet-diag +kmod-netlink-diag +kmod-tun
  USERID:=sing-box=5566:sing-box=5566
endef

define Package/sing-box/description
  Sing-box is a universal proxy platform which supports hysteria, SOCKS,
  Shadowsocks, ShadowTLS, Tor, trojan, VLess, VMess, WireGuard and so on.
  (Prebuilt aarch64 full build with acme, clash_api, dhcp, gvisor, quic,
  tailscale, utls, wireguard support.)
endef

define Build/Prepare
	$(INSTALL_DIR) $(PKG_BUILD_DIR)
	$(CP) ./src/sing-box $(PKG_BUILD_DIR)/sing-box
endef

define Build/Compile
endef

define Package/sing-box/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/sing-box $(1)/usr/bin/sing-box
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/sing-box.conf $(1)/etc/config/sing-box
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/sing-box.init $(1)/etc/init.d/sing-box
endef

$(eval $(call BuildPackage,sing-box))
EOF
echo "sing-box files:"; ls -la package/sing-box/src package/sing-box/files

echo "=== 5. ua3f package (prebuilt + luci) ==="
rm -rf package/ua3f
mkdir -p package/ua3f/src package/ua3f/files package/ua3f/luasrc package/ua3f/htdocs
cp /root/prebuilt/ua3f package/ua3f/src/ua3f
UA=/root/pkgsrc/ua3f-src/openwrt
cp "$UA/files/ua3f.conf" package/ua3f/files/
cp "$UA/files/ua3f.init" package/ua3f/files/
cp "$UA/files/uci-defaults" package/ua3f/files/
cp -r "$UA/luasrc/." package/ua3f/luasrc/
cp -r "$UA/htdocs/." package/ua3f/htdocs/
# i18n via po2lmo
if [ ! -x /root/pkgsrc/po2lmo ]; then
  if [ -f /root/immortalwrt-mt798x/feeds/luci/po2lmo/Makefile ]; then
    make -C /root/immortalwrt-mt798x/feeds/luci/po2lmo 2>/dev/null || true
    cp /root/immortalwrt-mt798x/feeds/luci/po2lmo/po2lmo /root/pkgsrc/ 2>/dev/null || true
  fi
  if [ ! -x /root/pkgsrc/po2lmo ]; then
    [ -d /root/pkgsrc/luci-src ] || git clone --depth=1 https://github.com/openwrt/luci.git /root/pkgsrc/luci-src 2>/dev/null || true
    make -C /root/pkgsrc/luci-src/po2lmo 2>/dev/null || true
    cp /root/pkgsrc/luci-src/po2lmo/po2lmo /root/pkgsrc/ 2>/dev/null || true
  fi
fi
if [ -x /root/pkgsrc/po2lmo ]; then
  /root/pkgsrc/po2lmo "$UA/po/zh_cn/ua3f.po" package/ua3f/files/ua3f.zh-cn.lmo
  echo "lmo generated"
else
  echo "WARN: po2lmo not available, skipping i18n"
fi
cat > package/ua3f/Makefile <<'EOF'
include $(TOPDIR)/rules.mk

PKG_NAME:=ua3f
PKG_VERSION:=3.6.0
PKG_RELEASE:=1

PKG_MAINTAINER:=SunBK201 <sunbk201gm@gmail.com>
PKG_LICENSE:=GPL-3.0-only

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/ua3f
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=Advanced HTTP Rewriting Proxy (prebuilt)
  URL:=https://github.com/SunBK201/UA3F
  DEPENDS:=+luci-compat +ipset +iptables +iptables-mod-tproxy +iptables-mod-extra +iptables-mod-ipopt +iptables-mod-nfqueue +iptables-mod-conntrack-extra +kmod-nf-conntrack-netlink
endef

define Package/ua3f/description
  Advanced HTTP Rewriting Proxy. (Prebuilt aarch64 build.)
endef

define Package/ua3f/conffiles
/etc/config/ua3f
endef

define Build/Prepare
	$(INSTALL_DIR) $(PKG_BUILD_DIR)
	$(CP) ./src/ua3f $(PKG_BUILD_DIR)/ua3f
endef

define Build/Compile
endef

define Package/ua3f/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ua3f $(1)/usr/bin/ua3f
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/ua3f.conf $(1)/etc/config/ua3f
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/ua3f.init $(1)/etc/init.d/ua3f
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/uci-defaults $(1)/etc/uci-defaults/luci-ua3f
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) ./files/ua3f.zh-cn.lmo $(1)/usr/lib/lua/luci/i18n/ua3f.zh-cn.lmo
	$(CP) ./luasrc/* $(1)/usr/lib/lua/luci/
	$(CP) ./htdocs/* $(1)/
endef

define Package/ua3f/postrm
#!/bin/sh
uci -q set ua3f.enabled.enabled=0
uci -q commit ua3f
[ -f "/etc/config/ucitrack" ] && {
	uci -q delete ucitrack.ua3f
	uci -q commit ucitrack
}
endef

$(eval $(call BuildPackage,ua3f))
EOF
echo "ua3f files:"; find package/ua3f -type f | head -20

echo "=== 6. .config generation ==="
cp defconfig/mt7981-ax3000.config .config
sed -i -E 's/^(CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_[^=]*)=y$/# \1 is not set/' .config
sed -i -E 's/^(CONFIG_TARGET_DEVICE_PACKAGES_mediatek_mt7981_DEVICE_[^=]*)=.*$/# \1 is not set/' .config
sed -i 's/^# CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_mt7981-360-t7-108M is not set$/CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_mt7981-360-t7-108M=y/' .config
cat >> .config <<'EOF'
CONFIG_PACKAGE_luci-app-openclash=y
CONFIG_PACKAGE_sing-box=y
CONFIG_PACKAGE_ua3f=y
CONFIG_PACKAGE_luci-app-harbor-file=y
CONFIG_PACKAGE_luci-app-singbox-ui=y
# CONFIG_PACKAGE_luci-app-filebrowser is not set
EOF
echo "--- running make defconfig ---"
make defconfig > /root/defconfig.log 2>&1 || { tail -80 /root/defconfig.log; exit 1; }
echo "--- verification ---"
echo "== enabled devices =="
grep -c "^CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_.*=y" .config
grep "^CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_.*=y" .config
echo "== our packages =="
grep -E "CONFIG_PACKAGE_(luci-app-openclash|sing-box|ua3f|luci-app-harbor-file|luci-app-singbox-ui)=y" .config || echo "MISSING!"
echo "== filebrowser =="
grep -E "luci-app-filebrowser" .config || echo "filebrowser: not set (OK)"
echo "== dnsmasq =="
grep -E "CONFIG_PACKAGE_dnsmasq" .config | head -5
echo "=== DONE stage_b ==="
