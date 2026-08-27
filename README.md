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

在官方 `defconfig/mt7981-ax3000.config` 包集合基础上，**只额外加入以下 5 个包，并明确排除 filebrowser**：

- **sing-box 1.13.19**（full 版，含 quic / utls / clash_api / gvisor / wireguard / tailscale / acme / dhcp）
- **UA3F 3.6.0**（含 LuCI 管理界面）
- **luci-app-openclash 0.47.156**（vernesong master 版）
- **luci-app-singbox-ui 2.4.0**
- **luci-app-harbor-file 1.0**（文件管理，替代 filebrowser，含中文语言包）

其余与官方一致：turboacc-mtk、eqos-mtk、mtwifi-cfg、upnp、ssr-plus 框架（不带内核）、dnsmasq-full 等，无冗余插件。

## 刷机方法

已刷 108M 大分区 U-Boot 的前提下：

1. **U-Boot WebUI 刷机**（推荐）：断电，按住 Reset 上电，浏览器访问 `192.168.1.1`，上传 `*-squashfs-sysupgrade.bin`
2. **LuCI 升级**：系统 → 备份/升级 → 选择 `*-squashfs-sysupgrade.bin`

> `*-squashfs-factory.bin` 仅用于救砖/特殊场景；`*-initramfs-kernel.bin` 可用于 U-Boot 网络启动。

## 从源码编译

```bash
# 1. 拉取源码（hanwckf 仓库，openwrt-21.02 分支）
git clone --depth=1 -b openwrt-21.02 https://github.com/hanwckf/immortalwrt-mt798x.git
cd immortalwrt-mt798x

# 2. 更新并安装 feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 3. 应用本仓库的定制
#    - 复制本仓库 .config 为项目 .config
#    - 应用 patches/ 下的 512MB 内存补丁
#    - 参考 package/ 与 scripts/ 加入 sing-box / ua3f / openclash / harbor-file / singbox-ui
#    （scripts/stage_a.sh ~ stage_b.sh 记录了完整步骤，含 Go 工具链准备）

# 4. 生成配置并构建（root 用户需 FORCE_UNSAFE_CONFIGURE=1）
make defconfig
FORCE_UNSAFE_CONFIGURE=1 make -j$(nproc) V=s

# 产物位于 bin/targets/mediatek/mt7981/
```

## 关键定制说明

### 512MB 内存（重要）
`target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/mt7981-360-t7-base.dtsi` 默认硬编码 256MB：
```diff
 	memory {
-		reg = <0 0x40000000 0 0x10000000>;   /* 256MB */
+		reg = <0 0x40000000 0 0x20000000>;   /* 512MB */
 	};
```
补丁见 [`patches/0001-360t7-memory-512mb.patch`](patches/0001-360t7-memory-512mb.patch)。**漏改会导致只识别 256MB。**

### sing-box / UA3F 的 Go 工具链
该树（openwrt-21.02）自带 Go 1.19，无法编译 sing-box 1.13（要求 ≥1.24.7）与 UA3F 3.6（要求 ≥1.23）。方案：
1. 在构建机上安装 Go 1.24.7（`scripts/stage_a.sh` 使用阿里云镜像下载）
2. 交叉编译 aarch64 静态二进制（`GOOS=linux GOARCH=arm64 CGO_ENABLED=0`）
3. 通过本仓库 `package/sing-box/`、`package/ua3f/` 的自定义 Makefile 打包进固件（`Build/Compile` 为空，仅安装预编译二进制 + 配置/init/LuCI 文件）

### OpenClash 版本
luci feed 内置的是 0.45.141-beta（依赖 ruby 且较旧），本固件改用 [vernesong/OpenClash](https://github.com/vernesong/OpenClash) master 的 0.47.156。OpenClash 运行时依赖 ruby，已一并编译进固件。

### 单设备构建
`defconfig/mt7981-ax3000.config` 默认启用全部 MT7981 设备，本仓库 `.config` 仅保留 `mt7981-360-t7-108M`，避免编译大量无关镜像。

## 目录结构

```
├── .config                     # 最终构建配置（仅 360t7-108M + 5 个新包）
├── patches/                    # 源码补丁（512MB 内存）
├── package/
│   ├── sing-box/               # 自定义 Makefile + init/config（二进制由 scripts 交叉编译）
│   └── ua3f/                   # 自定义 Makefile（LuCI 文件来自 UA3F 上游 openwrt/ 目录）
├── scripts/                    # 实际使用的构建脚本（含 Go 工具链准备、排错记录）
└── sha256sums                  # 固件校验和
```

## 致谢

- [hanwckf/immortalwrt-mt798x](https://github.com/hanwckf/immortalwrt-mt798x) & [bl-mt798x](https://github.com/hanwckf/bl-mt798x)
- [SunBK201/UA3F](https://github.com/SunBK201/UA3F)
- [vernesong/OpenClash](https://github.com/vernesong/OpenClash)
- [destan19/luci-app-harbor-file](https://github.com/destan19/luci-app-harbor-file)
- [ang3el7z/luci-app-singbox-ui](https://github.com/ang3el7z/luci-app-singbox-ui)
- [kenzok8/small-package](https://github.com/kenzok8/small-package)（sing-box 打包参考）
