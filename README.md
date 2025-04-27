# 使用 BBR暴力提速~~

# OpenWRT-CI
云编译OpenWRT固件

官方版：
https://github.com/immortalwrt/immortalwrt.git

高通版：
https://github.com/VIKINGYFY/immortalwrt.git

# 固件简要说明：

仅选择 QCA-ALL 编译

固件信息里的时间为编译开始的时间，方便核对上游源码提交时间。

MEDIATEK系列、QUALCOMMAX系列、ROCKCHIP系列、X86系列。

# 目录简要说明：

workflows——自定义CI配置

Scripts——自定义脚本

Config——自定义配置

# Tips ! 如果你想在本地进行编译的话 准备以下步骤(针对AX1800Pro)

## 注意

1. **不要用 root 用户进行编译**
2. 国内用户编译前最好准备好梯子

- 首先安装ubuntu20.04LTS
  ## 编译命令

1. 首先装好 Linux 系统， Ubuntu 20.04 LTS

2. 安装编译依赖

首先装好 Linux 系统，推荐 Ubuntu LTS

安装编译依赖

```bash
sudo apt -y update
sudo apt -y full-upgrade
sudo apt install -y dos2unix libfuse-dev
sudo bash -c 'bash <(curl -sL https://build-scripts.immortalwrt.org/init_build_environment.sh)'
	
```

## tips 上游不带有curl jq btop 但是cpu直接超频1.8G

3. 下载源代码，更新 feeds 并选择配置

   ```bash
   git clone https://github.com/VIKINGYFY/immortalwrt
   cd immortalwrt
   ./scripts/feeds update -a && ./scripts/feeds install -a
   make menuconfig
   
   ```

5. 第一次编译 一步到位

   ```bash
   make V=s download -j$(nproc) && make -j$(nproc)
   
   ```

## 编译完成后输出路径：bin/targets


## 二次编译直接运行

   ```bash
   make -j$(nproc)

   ```

## 以下个根据情况自行选择

1. 下载 dl 库，编译固件
（-j 后面是线程数，为便于排除错误推荐用单线程）

   ```bash
   make download -j8
   make -j1 V=s
   ```

2. 二次编译：

   ```bash
   cd immortalwrt
   git fetch && git reset --hard origin/main
   ./scripts/feeds update -a && ./scripts/feeds install -a
   make menuconfig
   make V=s -j$(nproc)
   ```

3. 如果需要重新配置：

   ```bash
   rm -rf .config
   make menuconfig
   make V=s -j$(nproc)
   ```
   
# 以下是该仓库对上游进行的调整

1.
.github/workflows/Auto-Clean.yml
去除每天早上6点自动清理

2.
.github/workflows/OWRT-ALL.yml
去除每天早上6点自动清理完成后自动编译

3.
.github/workflows/QCA-ALL.yml
去除每天早上6点自动清理完成后自动编译
设置每天早上6点自动编译
只保留IPQ60XX带wifi设备

4.
.github/workflows/WRT-CORE.yml
	sudo apt-get install -yqq clang-15
更新clang-15 方便后续编译daed
添加汉化步骤
	#$GITHUB_WORKSPACE/Scripts/feed.sh
#添加kiddin9的源

5.
Config/IPQ60XX-WIFI-YES.txt
固件编译只保留AX1800Pro

6.
Scripts/Packages.sh
去除主题luci-theme-argon替换
去除luci-app-advancedplus高级配置
使用不良0的带clashapi的homeproxy 无法显示需要开启无痕
去除VIKINGYFY/luci-app-advancedplus更新

7.
Scripts/Settings.sh
去除htop 去除wolplus 去除tailscale
去除主题 luci-theme-kucat luci-theme-design
内置 openssh-sftp-server 可以让FinalShell查看文件列表并且ssh连上不会自动断开
内置 jq 解析、查询、操作和格式化 JSON 数据
内置 btop 简单明了的系统资源占用查看工具
内置 curl 网络通信工具
内置 kmod-tcp-bbr BBR 拥塞控制算法替换Cubic(单车变摩托)
