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
  Advanced HTTP Rewriting Proxy. (Prebuilt aarch64 build, binary
  cross-compiled with Go 1.24, see scripts/stage_a.sh. LuCI files under
  luasrc/ htdocs/ are copied from SunBK201/UA3F openwrt/ directory.)
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
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
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
