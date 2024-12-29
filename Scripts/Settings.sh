#!/bin/bash

#修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
#添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_CI-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")

WIFI_SH="./package/base-files/files/etc/uci-defaults/990_set-wireless.sh"
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
	echo "$WRT_PACKAGE" >> ./.config
fi

#高通平台调整
if [[ $WRT_TARGET == *"IPQ"* ]]; then
	#取消nss相关feed
	echo "CONFIG_FEED_nss_packages=n" >> ./.config
	echo "CONFIG_FEED_sqm_scripts_nss=n" >> ./.config

	if [[ $WRT_TARGET == *"60XX"* ]]; then
		#设置NSS版本
		echo "CONFIG_NSS_FIRMWARE_VERSION_11_4=n" >> ./.config
		echo "CONFIG_NSS_FIRMWARE_VERSION_12_2=y" >> ./.config
	fi
fi

#修改jdc re-ss-01 (亚瑟) 的内核大小为12M
sed -i "/^define Device\/jdcloud_re-ss-01/,/^endef/ { /KERNEL_SIZE := 6144k/s//KERNEL_SIZE := 12288k/ }" target/linux/qualcommax/image/ipq60xx.mk

#修改jdc re-cs-02 (雅典娜) 的内核大小为12M
sed -i "/^define Device\/jdcloud_re-cs-02/,/^endef/ { /KERNEL_SIZE := 6144k/s//KERNEL_SIZE := 12288k/ }" target/linux/qualcommax/image/ipq60xx.mk

#修改jdc re-cs-07 (太乙) 的内核大小为12M
sed -i "/^define Device\/jdcloud_re-cs-07/,/^endef/ { /KERNEL_SIZE := 6144k/s//KERNEL_SIZE := 12288k/ }" target/linux/qualcommax/image/ipq60xx.mk

# 想要剔除的
# echo "CONFIG_PACKAGE_htop=n" >> ./.config
# echo "CONFIG_PACKAGE_iperf3=n" >> ./.config
echo "CONFIG_PACKAGE_luci-app-wolplus=n" >> ./.config
echo "CONFIG_PACKAGE_luci-app-tailscale=n" >> ./.config
echo "CONFIG_PACKAGE_luci-app-advancedplus=n" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-kucat=n" >> ./.config
# 一定要禁止编译这个coremark 不让会导致编译失败
echo "CONFIG_PACKAGE_coremark=n" >> ./.config

# 可以让FinalShell查看文件列表并且ssh连上不会自动断开
echo "CONFIG_PACKAGE_openssh-sftp-server=y" >> ./.config
# 解析、查询、操作和格式化 JSON 数据
echo "CONFIG_PACKAGE_jq=y" >> ./.config
# 简单明了的系统资源占用查看工具
echo "CONFIG_PACKAGE_btop=y" >> ./.config
# 多网盘存储
echo "CONFIG_PACKAGE_luci-app-alist=y" >> ./.config
# 强大的工具(需要添加源或git clone)
# echo "CONFIG_PACKAGE_luci-app-lucky=y" >> ./.config
# 网络通信工具
echo "CONFIG_PACKAGE_curl=y" >> ./.config
# BBR 拥塞控制算法(终端侧)
# echo "CONFIG_PACKAGE_kmod-tcp-bbr=y" >> ./.config
# echo "CONFIG_DEFAULT_tcp_bbr=y" >> ./.config
# 磁盘管理
echo "CONFIG_PACKAGE_luci-app-diskman=y" >> ./.config
# 其他调整
# 大鹅
echo "CONFIG_PACKAGE_luci-app-daed=y" >> ./.config
# 大鹅-next
# echo "CONFIG_PACKAGE_luci-app-daed-next=y" >> ./.config
＃ 连上ssh不会断开并且显示文件管理
echo "CONFIG_PACKAGE_openssh-sftp-server"=y
# echo "CONFIG_PACKAGE_kmod-tcp-bbr=y" >> ./.config
# echo "CONFIG_DEFAULT_tcp_bbr=y" >> ./.config
# docker只能集成
echo "CONFIG_PACKAGE_luci-app-dockerman=y" >> ./.config
# 集成Lucky(大吉)
echo "CONFIG_PACKAGE_luci-app-lucky=y" >> ./.config
# qBittorrent
echo "CONFIG_PACKAGE_luci-app-qbittorrent=y" >> ./.config
# 添加Homebox内网测速
# echo "CONFIG_PACKAGE_luci-app-homebox=y" >> ./.config
# V2rayA
echo "CONFIG_PACKAGE_luci-app-v2raya=y" >> ./.config
# NSS的sqm
echo "CONFIG_PACKAGE_luci-app-sqm=y" >> ./.config
echo "CONFIG_PACKAGE_sqm-scripts-nss=y" >> ./.config
# istore
echo "CCONFIG_PACKAGE_luci-app-istorex=y" >> ./.config
# QuickStart
echo "CONFIG_PACKAGE_luci-app-quickstart=y" >> ./.config
