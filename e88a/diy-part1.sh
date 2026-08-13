#!/bin/bash
#===============================================
# Description: DIY script (run before feeds update)
# File name: diy-part1.sh
# Lisence: MIT
# Author: P3TERX (modified for JEA-E88A)
#===============================================

# 修改版本为编译日期，数字类型。
date_version=$(date +"%Y%m")
echo $date_version > version

# 为iStoreOS固件版本加上编译作者
author="e88a"
sed -i "s/DISTRIB_DESCRIPTION.*/DISTRIB_DESCRIPTION='%D %V ${date_version} by ${author}'/g" package/base-files/files/etc/openwrt_release
sed -i "s/OPENWRT_RELEASE.*/OPENWRT_RELEASE=\"%D %V ${date_version} by ${author}\"/g" package/base-files/files/usr/lib/os-release
