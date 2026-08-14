#!/bin/bash
# ============================================================
# 由 dts-src/rk3588-jea-e88a.dts 重新生成 987 kernel patch
#
# 设计原则:
#   - dts 自包含, 仅 #include 主线 "rk3588.dtsi", 不依赖任何自定义 dtsi
#   - 板级内容(RK806 PMIC / 供电 / modem 三段电源 / RTC / 音频 / LED / ramoops)
#     全部内联在单个 dts 文件内
#   - patch 仅含: dts(new file) + Makefile(dtb 注册), 不再有 dtsi diff
#
# 用法:
#   cd e88a/kernel-rockchip && bash generate_kernel_patch.sh
# ============================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$DIR/dts-src/rk3588-jea-e88a.dts"
OUT="$DIR/patches/987-rockchip-rk3588-jea-e88a-kernel.patch"

if [ ! -f "$SRC" ]; then
	echo "ERROR: source dts not found: $SRC" >&2
	exit 1
fi

# 归一化行尾 -> LF, 并去掉尾部空行
TMP="$(mktemp)"
sed 's/\r$//' "$SRC" > "$TMP"
while [ -z "$(tail -n1 "$TMP")" ]; do
	sed -i '$ d' "$TMP"
done
N=$(wc -l < "$TMP")

{
	echo "diff --git a/arch/arm64/boot/dts/rockchip/rk3588-jea-e88a.dts b/arch/arm64/boot/dts/rockchip/rk3588-jea-e88a.dts"
	echo "new file mode 100644"
	echo "index 000000000..000000001"
	echo "--- /dev/null"
	echo "+++ b/arch/arm64/boot/dts/rockchip/rk3588-jea-e88a.dts"
	echo "@@ -0,0 +1,${N} @@"
	sed 's/^/+/' "$TMP"
	echo ""
	echo "diff --git a/arch/arm64/boot/dts/rockchip/Makefile b/arch/arm64/boot/dts/rockchip/Makefile"
	echo "index 000000000..000000000 100644"
	echo "--- a/arch/arm64/boot/dts/rockchip/Makefile"
	echo "+++ b/arch/arm64/boot/dts/rockchip/Makefile"
	echo "@@ -105,3 +105,4 @@ dtb-\$(CONFIG_ARCH_ROCKCHIP) += rk3568-rock-3b.dtb"
	echo " dtb-\$(CONFIG_ARCH_ROCKCHIP) += rk3568-rock-3b.dtb"
	echo " dtb-\$(CONFIG_ARCH_ROCKCHIP) += rk3588-armsom-sige7.dtb"
	echo "+dtb-\$(CONFIG_ARCH_ROCKCHIP) += rk3588-jea-e88a.dtb"
	echo ""
} > "$OUT"

rm -f "$TMP"
echo "Generated: $OUT  (dts $N lines, 2 diff sections: dts + Makefile)"
