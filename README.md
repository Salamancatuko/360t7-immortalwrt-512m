# 360T7 (MT7981) ImmortalWrt 定制固件

基于 [hanwckf/immortalwrt-mt798x](https://github.com/hanwckf/immortalwrt-mt798x)（`openwrt-21.02` 分支）为 360 T7 编译的定制 ImmortalWrt 固件。

| 项目 | 值 |
|---|---|
| SoC | MediaTek MT7981 (Filogic 820, Cortex-A53 双核) |
| 内存 | **512MB**（原厂 256MB 改焊，dts 已修正） |
| NAND | W25N01KV |
| 内核 | Linux 5.4.284（含 MTK 闭源 Wi-Fi 驱动 kmod-mt_wifi） |

固件与校验和见 [Releases](../../releases)。

## 固件包含的插件

在官方 `defconfig/mt7981-ax3000.config` 包集合基础上额外加入以下 3 个包：

- **UA3F**（含 LuCI 管理界面）
- **luci-app-openclash**（vernesong master 版）
- **luci-app-harbor-file**（文件管理，含中文语言包）

## 致谢

- [hanwckf/immortalwrt-mt798x](https://github.com/hanwckf/immortalwrt-mt798x) & [bl-mt798x](https://github.com/hanwckf/bl-mt798x)
- [SunBK201/UA3F](https://github.com/SunBK201/UA3F)
- [vernesong/OpenClash](https://github.com/vernesong/OpenClash)
- [destan19/luci-app-harbor-file](https://github.com/destan19/luci-app-harbor-file)
