# 使用 BBR+Cake暴力提速(运营商都要找你要宽带)

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

   ```bash
   sudo apt update -y
   sudo apt full-upgrade -y
   sudo apt install -y ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
   bzip2 ccache cmake cpio curl device-tree-compiler fastjar flex gawk gettext gcc-multilib g++-multilib \
   git gperf haveged help2man intltool libc6-dev-i386 libelf-dev libglib2.0-dev libgmp3-dev libltdl-dev \
   libmpc-dev libmpfr-dev libncurses5-dev libncursesw5-dev libreadline-dev libssl-dev libtool lrzsz \
   mkisofs msmtp nano ninja-build p7zip p7zip-full patch pkgconf python2.7 python3 python3-pip libpython3-dev qemu-utils \
   rsync scons squashfs-tools subversion swig texinfo uglifyjs upx-ucl unzip vim wget xmlto xxd zlib1g-dev
   
   ```
## tips 上游不带有curl jq btop 但是cpu直接超频1.8G

3. 下载源代码，更新 feeds 并选择配置

   ```bash
   git clone https://github.com/VIKINGYFY/immortalwrt
   cd immortalwrt
   ./scripts/feeds update -a && ./scripts/feeds install -a
   make menuconfig
   
   ```

4. ！！！必须要的 否则编译不出来！！！ tips注意这个版本上游高通是锁1024M最大内存 改成512M 不影响日常使用

   ```bash
   echo "CONFIG_IPQ_MEM_PROFILE_1024=n" >> ./.config
   echo "CONFIG_IPQ_MEM_PROFILE_512=y" >> ./.config
   echo "CONFIG_ATH11K_MEM_PROFILE_1G=n" >> ./.config
   echo "CONFIG_ATH11K_MEM_PROFILE_512M=y" >> ./.config
   
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
去除每天早上4点自动清理

2.
.github/workflows/OWRT-ALL.yml
去除每天早上4点自动清理后自动编译

3.
.github/workflows/QCA-ALL.yml
去除每天早上4点自动清理后自动编译
每天早上4点自动编译

4.
.github/workflows/WRT-CORE.yml
	sudo apt-get update -yqq
	sudo apt-get install -yqq clang-13
更新clang-13 方便后续编译daed
	#$GITHUB_WORKSPACE/Scripts/feed.sh
#添加kiddin9的源

5.
Config/IPQ60XX-WIFI-YES.txt
固件编译只保留AX1800Pro

6.
Scripts/Packages.sh
去除主题jerrykuku/luci-theme-argon替换
去除主题sirpdboy/luci-theme-kucatgen更新
使用不良0的带clashapi的homeproxy 无法显示需要开启无痕
去除VIKINGYFY/luci-app-advancedplus更新
替换golang成最新版的golang

7.
Scripts/Settings.sh
去除htop 去除iperf3 去除wolplus 去除tailscale
去除主题 luci-theme-kucat luci-theme-design
内置 openssh-sftp-server 可以让FinalShell查看文件列表并且ssh连上不会自动断开
内置 jq 解析、查询、操作和格式化 JSON 数据
内置 btop 简单明了的系统资源占用查看工具
内置 curl 网络通信工具
内置 kmod-tcp-bbr BBR 拥塞控制算法替换Cubic(单车变摩托)

# tips
在 Ubuntu 24.04 上，Python 2 已不再默认提供支持。如果你只需要安装 Python 2，并希望避免复杂的操作，最简单的方式是通过以下步骤手动安装：

1. 手动安装 Python 2
可以从官方 Python 源码编译并安装 Python 2.7，这样不依赖 PPA 或不稳定的源。

步骤：
## 1.更新系统并安装依赖： 运行以下命令来更新系统并安装编译 Python 所需的依赖：
```bash
sudo apt update
sudo apt install build-essential libssl-dev libbz2-dev libreadline-dev libsqlite3-dev zlib1g-dev libncurses5-dev libncursesw5-dev libffi-dev liblzma-dev
```
## 2.下载 Python 2.7 源代码： 从官方 Python 网站下载 Python 2.7 的源代码：
```bash
cd /usr/src
sudo wget https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz
```
## 3.解压源代码：
```bash
sudo tar xzf Python-2.7.18.tgz
cd Python-2.7.18
```
## 4.编译并安装 Python 2：
```bash
sudo ./configure --enable-optimizations
sudo make altinstall
```
make altinstall 会避免覆盖系统中的默认 python3 可执行文件。
## 5.验证安装：
你可以使用以下命令确认 Python 2 已成功安装：
```bash
python2.7 --version
```

