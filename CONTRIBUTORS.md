# 贡献者 / Contributors

## 项目与硬件
- **Salamancatuko** — 项目发起与维护；路由器硬件改装（内存 256MB → 512MB）、刷入 108M 大分区 U-Boot、固件实机测试

## 构建工程
- **DeepSeek Harness**（AI agent，模型 `deepseek-v4-flash`）— 固件编译工程实施：
  - 搭建 WSL2 构建环境（独立 Debian 12 发行版；规避 Ubuntu 26.04 的 GCC 15 / Python 3.14 不兼容与 WSL 的 Windows PATH 注入问题）
  - 512MB 内存 DTS 修正并在最终 DTB 中验证
  - UA3F 3.7.0（宿主机 Go 1.24 交叉编译 + LuCI/中文 lmo 打包）、luci-app-openclash 0.48.002、luci-app-harbor-file 1.0（含中文语言包）集成
  - 精简配置裁剪：仅保留 `luci-app-argon-config` / `luci-theme-argon`，移除其余全部可选插件
  - 全量编译、产物校验（镜像结构、包清单、rootfs 解包核对）与发布

## 上游项目
- [hanwckf/immortalwrt-mt798x](https://github.com/hanwckf/immortalwrt-mt798x)、[hanwckf/bl-mt798x](https://github.com/hanwckf/bl-mt798x)
- [SunBK201/UA3F](https://github.com/SunBK201/UA3F)
- [vernesong/OpenClash](https://github.com/vernesong/OpenClash)
- [destan19/luci-app-harbor-file](https://github.com/destan19/luci-app-harbor-file)
