#!/bin/bash
#===============================================
# Description: DIY script (run after feeds install)
# File name: diy-part2.sh
# Lisence: MIT
# Author: P3TERX (modified for JEA-E88A)
# Blog: https://p3terx.com
#
# JEA-E88A (JWIPC, RK3588) board porting for iStoreOS 24.10
# Copy this whole directory (e88a-board/) next to the build workflow,
# then this script injects: armv8.mk device + uboot Makefile +
# uboot/kernel patches + 02_network. Source tree stays clean for git pull.
#===============================================

BOARD_DIR=${BOARD_DIR:-$GITHUB_WORKSPACE/e88a-board}

#移植设备
# target/linux/rockchip/image/armv8.mk 添加 e88a 设备型号
echo -e "\\ndefine Device/jwipc_jea-e88a
  DEVICE_VENDOR := JWIPC
  DEVICE_MODEL := JEA-E88A
  SOC := rk3588
  DEVICE_DTS := rockchip/rk3588-jea-e88a
  UBOOT_DEVICE_NAME := jea-e88a-rk3588
  DEVICE_PACKAGES := kmod-r8169 kmod-usb-net-rtl8152 \\
	kmod-usb-net-cdc-ncm kmod-usb-net-rndis \\
	kmod-usb-serial-option kmod-usb-serial-qmi-wwan kmod-usb-serial-wwan
endef
TARGET_DEVICES += jwipc_jea-e88a" >> target/linux/rockchip/image/armv8.mk

# 复制修改好的 uboot-rockchip/Makefile 到对应目录（含 U-Boot/jea-e88a-rk3588 定义）
cp -f $BOARD_DIR/uboot-rockchip/Makefile package/boot/uboot-rockchip/Makefile

# 复制 uboot patch（新增 jea-e88a-rk3588 defconfig + U-Boot DTS）
cp -f $BOARD_DIR/uboot-rockchip/patches/987-rk3588-jea-e88a-uboot.patch package/boot/uboot-rockchip/patches/987-rk3588-jea-e88a-uboot.patch

# 复制 kernel patch（新增 rk3588-jea-e88a.dts + helper dtsi + Makefile dtb 注册）
cp -f $BOARD_DIR/kernel-rockchip/patches/987-rockchip-rk3588-jea-e88a-kernel.patch target/linux/rockchip/patches-6.6/987-rockchip-rk3588-jea-e88a-kernel.patch

# 复制 02_network
cp -f $BOARD_DIR/kernel-rockchip/02_network target/linux/rockchip/armv8/base-files/etc/board.d/02_network


# iStoreOS-settings
git clone --depth=1 -b main https://github.com/xiaomeng9597/istoreos-settings package/default-settings


echo "
CONFIG_TARGET_ROOTFS_TARGZ=y
" >> .config

# add qmodem
echo 'src-git qmodem https://github.com/FUjr/QModem.git;main' >> feeds.conf.default
./scripts/feeds update qmodem && ./scripts/feeds install -a -f -p qmodem
# git clone -b v3.0.0 --depth=1 https://github.com/FUjr/QModem.git package/qmodem
sed -i "s/CONFIG_PACKAGE_sms-tool/#CONFIG_PACKAGE_sms-tool/g" .config  
sed -i "s/CONFIG_PACKAGE_luci-app-modem/#CONFIG_PACKAGE_luci-app-modem/g" .config  
sed -i "s/CONFIG_PACKAGE_luci-app-sms-tool/#CONFIG_PACKAGE_luci-app-sms-tool/g" .config
echo "
CONFIG_PACKAGE_luci-i18n-qmodem-zh-cn=y
# CONFIG_PACKAGE_luci-i18n-qmodem-hc-zh-cn=y
# CONFIG_PACKAGE_luci-i18n-qmodem-mwan-zh-cn=y
# CONFIG_PACKAGE_luci-i18n-qmodem-ru is not set
CONFIG_PACKAGE_luci-i18n-qmodem-sms-zh-cn=y
CONFIG_PACKAGE_luci-app-qmodem=y
CONFIG_PACKAGE_luci-app-modem=n
CONFIG_PACKAGE_luci-app-qmodem_INCLUDE_vendor-qmi-wwan=y
# CONFIG_PACKAGE_luci-app-qmodem_INCLUDE_generic-qmi-wwan is not set
CONFIG_PACKAGE_luci-app-qmodem_USE_TOM_CUSTOMIZED_QUECTEL_CM=y
# CONFIG_PACKAGE_luci-app-qmodem_USING_QWRT_QUECTEL_CM_5G is not set
# CONFIG_PACKAGE_luci-app-qmodem_USING_NORMAL_QUECTEL_CM is not set
# CONFIG_PACKAGE_luci-app-qmodem_INCLUDE_ADD_PCI_SUPPORT=y
# CONFIG_PACKAGE_luci-app-qmodem_INCLUDE_ADD_QFIREHOSE_SUPPORT is not set
#CONFIG_PACKAGE_luci-app-qmodem-hc=y
#CONFIG_PACKAGE_luci-app-qmodem-mwan=y
CONFIG_PACKAGE_luci-app-qmodem-sms=y
#CONFIG_PACKAGE_luci-app-qmodem-ttl=y
CONFIG_PACKAGE_qmodem=y
CONFIG_PACKAGE_quectel-CM-5G=y
CONFIG_PACKAGE_quectel-CM-5G-M=y
" >> .config

