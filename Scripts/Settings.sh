#!/bin/bash

#修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
#添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")

WIFI_SH=$(find ./target/linux/{mediatek/filogic,qualcommax}/base-files/etc/uci-defaults/ -type f -name "*set-wireless.sh")
WIFI_UC="./package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"
if [ -f "$WIFI_SH" ]; then
	#修改WIFI名称
	sed -i "s/BASE_SSID='.*'/BASE_SSID='$WRT_SSID'/g" $WIFI_SH
	#修改WIFI密码
	sed -i "s/BASE_WORD='.*'/BASE_WORD='$WRT_WORD'/g" $WIFI_SH
elif [ -f "$WIFI_UC" ]; then
	#修改WIFI名称
	sed -i "s/ssid='.*'/ssid='$WRT_SSID'/g" $WIFI_UC
	#修改WIFI密码
	sed -i "s/key='.*'/key='$WRT_WORD'/g" $WIFI_UC
	#修改WIFI地区
	sed -i "s/country='.*'/country='CN'/g" $WIFI_UC
	#修改WIFI加密
	sed -i "s/encryption='.*'/encryption='psk2+ccmp'/g" $WIFI_UC
fi

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

#配置文件修改
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config

#手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
	echo -e "$WRT_PACKAGE" >> ./.config
fi

#高通平台调整
DTS_PATH="./target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/"
if [[ $WRT_TARGET == *"QUALCOMMAX"* ]]; then
	#取消nss相关feed
	echo "CONFIG_FEED_nss_packages=n" >> ./.config
	echo "CONFIG_FEED_sqm_scripts_nss=n" >> ./.config
	#设置NSS版本
	echo "CONFIG_NSS_FIRMWARE_VERSION_11_4=n" >> ./.config
	echo "CONFIG_NSS_FIRMWARE_VERSION_12_2=y" >> ./.config
 	# echo "CONFIG_NSS_FIRMWARE_VERSION_12_5=y" >> ./.config
	#无WIFI配置调整Q6大小
	if [[ "${WRT_CONFIG,,}" == *"wifi"* && "${WRT_CONFIG,,}" == *"no"* ]]; then
		find $DTS_PATH -type f ! -iname '*nowifi*' -exec sed -i 's/ipq\(6018\|8074\).dtsi/ipq\1-nowifi.dtsi/g' {} +
		echo "qualcommax set up nowifi successfully!"
	fi
fi


if [[ $WRT_TARGET != *"X86"* ]]; then
	echo "CONFIG_vmease=y" >> ./.config

	#编译器优化
	echo "CONFIG_TARGET_OPTIONS=y" >> ./.config
	echo "CONFIG_TARGET_OPTIMIZATION=\"-O2 -pipe -march=armv8-a+crypto+crc -mcpu=cortex-a53+crypto+crc -mtune=cortex-a53\"" >> ./.config
fi

if [[ $WRT_TARGET == *"X86"* ]]; then
	echo "CONFIG_TARGET_OPTIONS=y" >> ./.config
 	# 通用 x86_64 优化
	echo "CONFIG_TARGET_OPTIMIZATION=\"-O2 -pipe -march=x86-64 -mtune=generic\"" >> ./.config
 	# 针对 Intel 或 AMD 处理器 适用于 Intel 6 代及更新（如 Coffee Lake、Comet Lake、Tiger Lake 等）
  	# echo "CONFIG_TARGET_OPTIMIZATION=\"-O2 -pipe -march=skylake -mtune=skylake -mfpmath=sse -msse4.2 -mavx2 -mfma\"" >> ./.config
  	# AMD Ryzen（Zen 及更新）适用于 AMD Ryzen（Zen、Zen 2、Zen 3、Zen 4）针对 Zen 3 架构优化（如果是 Zen 2，改为 znver2，Zen 4 用 znver4）优化 AVX2 代码
   	# echo "CONFIG_TARGET_OPTIMIZATION=\"-O2 -pipe -march=znver3 -mtune=znver3 -mfpmath=sse -msse4.2 -mavx2 -mfma -mprefer-vector-width=256\"" >> ./.config

	这个变量决定了 根文件系统（RootFS）分区的大小 默认是256M 单位MB
    	# echo "CONFIG_TARGET_ROOTFS_PARTSIZE=3096" >> .config

	# 这个变量决定了内核分区的大小，通常是 16MB 或 32MB
      	echo "CONFIG_TARGET_KERNEL_PARTSIZE=16" >> .config
fi


#修复dropbear
sed -i "s/Interface/DirectInterface/" ./package/network/services/dropbear/files/dropbear.config

#coremark修复
# sed -i 's/mkdir \$(PKG_BUILD_DIR)\/\$(ARCH)/mkdir -p \$(PKG_BUILD_DIR)\/\$(ARCH)/g' ../feeds/packages/utils/coremark/Makefile

# eBPF
echo "CONFIG_DEVEL=y" >> ./.config
echo "CONFIG_BPF_TOOLCHAIN_HOST=y" >> ./.config
echo "# CONFIG_BPF_TOOLCHAIN_NONE is not set" >> ./.config
echo "CONFIG_KERNEL_BPF_EVENTS=y" >> ./.config
echo "CONFIG_KERNEL_CGROUP_BPF=y" >> ./.config
echo "CONFIG_KERNEL_DEBUG_INFO=y" >> ./.config
echo "CONFIG_KERNEL_DEBUG_INFO_BTF=y" >> ./.config
echo "# CONFIG_KERNEL_DEBUG_INFO_REDUCED is not set" >> ./.config
echo "CONFIG_KERNEL_XDP_SOCKETS=y" >> ./.config

# BPFtool 支持 eBPF 程序 反汇编（disassembly）
echo "CONFIG_PACKAGE_bpftool-full=y" >> ./.config

# echo "CONFIG_BPF=y" >> ./target/linux/qualcommax/config-6.6
# echo "CONFIG_BPF_SYSCALL=y" >> ./target/linux/qualcommax/config-6.6
# echo "CONFIG_BPF_JIT=y" >> ./target/linux/qualcommax/config-6.6
# echo "CONFIG_CGROUPS=y" >> ./target/linux/qualcommax/config-6.6
# echo "CONFIG_KPROBES=y" >> ./target/linux/qualcommax/config-6.6
# echo "CONFIG_NET_INGRESS=y" >> ./target/linux/qualcommax/config-6.6
# echo "CONFIG_NET_EGRESS=y" >> ./target/linux/qualcommax/config-6.6
# echo "CONFIG_NET_SCH_INGRESS=m" >> ./target/linux/qualcommax/config-6.6
# echo "CONFIG_NET_CLS_BPF=m" >> ./target/linux/qualcommax/config-6.6
# echo "CONFIG_NET_CLS_ACT=y" >> ./target/linux/qualcommax/config-6.6
# echo "CONFIG_BPF_STREAM_PARSER=y" >> ./target/linux/qualcommax/config-6.6
# echo "CONFIG_DEBUG_INFO=y" >> ./target/linux/qualcommax/config-6.6
# echo "# CONFIG_DEBUG_INFO_REDUCED is not set" >> ./target/linux/qualcommax/config-6.6
# echo "CONFIG_DEBUG_INFO_BTF=y" >> ./target/linux/qualcommax/config-6.6
# echo "CONFIG_KPROBE_EVENTS=y" >> ./target/linux/qualcommax/config-6.6
# echo "CONFIG_BPF_EVENTS=y" >> ./target/linux/qualcommax/config-6.6

#修改jdc re-ss-01 (亚瑟) 的内核大小为12M
sed -i "/^define Device\/jdcloud_re-ss-01/,/^endef/ { /KERNEL_SIZE := 6144k/s//KERNEL_SIZE := 12288k/ }" target/linux/qualcommax/image/ipq60xx.mk
#修改jdc re-cs-02 (雅典娜) 的内核大小为12M
sed -i "/^define Device\/jdcloud_re-cs-02/,/^endef/ { /KERNEL_SIZE := 6144k/s//KERNEL_SIZE := 12288k/ }" target/linux/qualcommax/image/ipq60xx.mk
#修改jdc re-cs-07 (太乙) 的内核大小为12M
sed -i "/^define Device\/jdcloud_re-cs-07/,/^endef/ { /KERNEL_SIZE := 6144k/s//KERNEL_SIZE := 12288k/ }" target/linux/qualcommax/image/ipq60xx.mk
#修改mr7350 (领势LINKSYS MR7350) 的内核大小为12M
sed -i "/^define Device\/linksys_mr7350/,/^endef/ { /KERNEL_SIZE := 6144k/s//KERNEL_SIZE := 12288k/ }" target/linux/qualcommax/image/ipq60xx.mk
#修改redmi_ax5-jdcloud(京东云红米AX5) 的内核大小为12M
sed -i "/^define Device\/redmi_ax5-jdcloud/,/^endef/ { /KERNEL_SIZE := 6144k/s//KERNEL_SIZE := 12288k/ }" target/linux/qualcommax/image/ipq60xx.mk
# 想要剔除的
# echo "CONFIG_PACKAGE_htop=n" >> ./.config
# echo "CONFIG_PACKAGE_iperf3=n" >> ./.config
echo "CONFIG_PACKAGE_luci-app-wolplus=n" >> ./.config
echo "CONFIG_PACKAGE_luci-app-tailscale=n" >> ./.config
echo "CONFIG_PACKAGE_luci-app-advancedplus=n" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-kucat=n" >> ./.config
echo "CONFIG_PACKAGE_luci-app-mihomo=n" >> ./.config
# 使用opkg替换apk安装器
# echo "CONFIG_PACKAGE_opkg=y" >> ./.config
# echo "CONFIG_OPKG_USE_CURL=y" >> ./.config
# echo "# CONFIG_USE_APK is not set" >> ./.config
# 可以让FinalShell查看文件列表并且ssh连上不会自动断开
echo "CONFIG_PACKAGE_openssh-sftp-server=y" >> ./.config
# 解析、查询、操作和格式化 JSON 数据
echo "CONFIG_PACKAGE_jq=y" >> ./.config
# base64 修改码云上的内容 需要用到
echo "CONFIG_PACKAGE_coreutils-base64=y" >> ./.config
echo "CONFIG_PACKAGE_coreutils=y" >> ./.config
# 简单明了的系统资源占用查看工具
echo "CONFIG_PACKAGE_btop=y" >> ./.config
# 多网盘存储
echo "CONFIG_PACKAGE_luci-app-alist=y" >> ./.config
# 强大的工具Lucky大吉(需要添加源或git clone)
echo "CONFIG_PACKAGE_luci-app-lucky=y" >> ./.config
# 网络通信工具
echo "CONFIG_PACKAGE_curl=y" >> ./.config
echo "CONFIG_PACKAGE_tcping=y" >> ./.config
# BBR 拥塞控制算法(终端侧)
# echo "CONFIG_PACKAGE_kmod-tcp-bbr=y" >> ./.config
# echo "CONFIG_DEFAULT_tcp_bbr=y" >> ./.config
# 磁盘管理
echo "CONFIG_PACKAGE_luci-app-diskman=y" >> ./.config
echo "CONFIG_PACKAGE_cfdisk=y" >> ./.config
# 其他调整
# 大鹅
echo "CONFIG_PACKAGE_luci-app-daed=y" >> ./.config
# 大鹅-next
# echo "CONFIG_PACKAGE_luci-app-daed-next=y" >> ./.config
# 连上ssh不会断开并且显示文件管理
echo "CONFIG_PACKAGE_opeh-sftp-server"=y
# docker只能集成
echo "CONFIG_PACKAGE_luci-app-dockerman=y" >> ./.config
# qBittorrent
echo "CONFIG_PACKAGE_luci-app-qbittorrent=y" >> ./.config
# 添加Homebox内网测速
# echo "CONFIG_PACKAGE_luci-app-homebox=y" >> ./.config
# V2rayA
echo "CONFIG_PACKAGE_luci-app-v2raya=y" >> ./.config
echo "CONFIG_PACKAGE_v2ray-core=y" >> ./.config
echo "CONFIG_PACKAGE_v2ray-geoip=y" >> ./.config
echo "CONFIG_PACKAGE_v2ray-geosite=y" >> ./.config
# NSS的sqm
# echo "CONFIG_PACKAGE_luci-app-sqm=y" >> ./.config
# echo "CONFIG_PACKAGE_sqm-scripts-nss=y" >> ./.config
# NSS MASH
# echo "CONFIG_ATH11K_NSS_MESH=y" >> ./.config
# 不知道什么 加上去
# echo "CONFIG_PACKAGE_MAC80211_NSS_REDIRECT=y" >> ./.config
# istore 编译报错
# echo "CONFIG_PACKAGE_luci-app-istorex=y" >> ./.config
# QuickStart
# echo "CONFIG_PACKAGE_luci-app-quickstart=y" >> ./.config
# filebrowser-go
# echo "CONFIG_PACKAGE_luci-app-filebrowser-go=y" >> ./.config
# 图形化web UI luci-app-uhttpd	
echo "CONFIG_PACKAGE_luci-app-uhttpd=y" >> ./.config
# 多播
# echo "CONFIG_PACKAGE_luci-app-syncdial=y" >> ./.config
# MosDNS
echo "CONFIG_PACKAGE_luci-app-mosdns=y" >> ./.config
# Natter2 报错
# echo "CONFIG_PACKAGE_luci-app-natter2=y" >> ./.config
# 文件管理器
echo "CONFIG_PACKAGE_luci-app-filemanager=y" >> ./.config
# 不要coremark 避免多线程编译报错
# echo "CONFIG_PACKAGE_coremark=n" >> ./.config
# 基于Golang的多协议转发工具
echo "CONFIG_PACKAGE_luci-app-gost=y" >> ./.config
# Go语言解析
echo "CONFIG_PACKAGE_golang=y" >> ./.config
# Git
echo "CONFIG_PACKAGE_git-http=y" >> ./.config
# Nginx替换Uhttpd
# echo "CONFIG_PACKAGE_nginx-mod-luci=y" >> ./.config
# Nginx的图形化界面
# echo "CONFIG_PACKAGE_luci-nginxer=y" >> ./.config
# HAProxy 比Nginx更强大的反向代理服务器
echo "CONFIG_PACKAGE_luci-app-haproxy-tcp=y" >> ./.config
# Adguardhome去广告
echo "CONFIG_PACKAGE_luci-app-adguardhome=y" >> ./.config
# cloudflre速度筛选器
echo "CONFIG_PACKAGE_luci-app-cloudflarespeedtest=y" >> ./.config
# OpenClash
echo "CONFIG_PACKAGE_luci-app-openclash=y" >> ./.config
# nfs-kernel-server共享
echo "CONFIG_PACKAGE_nfs-kernel-server=y" >> ./.config
