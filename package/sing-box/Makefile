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
  tailscale, utls, wireguard support. Binary is cross-compiled with Go 1.24,
  see scripts/stage_a.sh.)
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
