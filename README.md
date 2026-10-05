# 360T7 (MT7981) ImmortalWrt 定制固件

基于 [hanwckf/immortalwrt-mt798x](https://github.com/hanwckf/immortalwrt-mt798x)（`openwrt-21.02` 分支）为 360 T7 编译的定制 ImmortalWrt 固件。

| 项目 | 值 |
|---|---|
| 路由器 | 360 T7 |
| SoC | MediaTek MT7981 (Filogic 820, Cortex-A53 双核) |
| 内存 | **512MB**（原厂 256MB 改焊，dts 已修正） |
| NAND | W25N01KV |
| U-Boot | 108M 大分区版（ubootmod） |
| 内核 | Linux 5.4.284（含 MTK 闭源 Wi-Fi 驱动 kmod-mt_wifi） |

固件与校验和见 [Releases](../../releases)。

## 固件包含的插件

在官方 `defconfig/mt7981-ax3000.config` 包集合基础上额外加入以下 5 个包：

- **sing-box 1.13.19**（full 版，含 quic / utls / clash_api / gvisor / wireguard / tailscale / acme / dhcp）
- **UA3F 3.6.0**（含 LuCI 管理界面）
- **luci-app-openclash 0.47.156**（vernesong master 版）
- **luci-app-singbox-ui 2.4.0**
- **luci-app-harbor-file 1.0**（文件管理，替代 filebrowser，含中文语言包）

其余与官方一致：turboacc-mtk、eqos-mtk、mtwifi-cfg、upnp、ssr-plus 框架（不带内核）、dnsmasq-full 等。
## 致谢

- [hanwckf/immortalwrt-mt798x](https://github.com/hanwckf/immortalwrt-mt798x) & [bl-mt798x](https://github.com/hanwckf/bl-mt798x)
- [SunBK201/UA3F](https://github.com/SunBK201/UA3F)
- [vernesong/OpenClash](https://github.com/vernesong/OpenClash)
- [destan19/luci-app-harbor-file](https://github.com/destan19/luci-app-harbor-file)
- [ang3el7z/luci-app-singbox-ui](https://github.com/ang3el7z/luci-app-singbox-ui)
- [kenzok8/small-package](https://github.com/kenzok8/small-package)（sing-box 打包参考）
