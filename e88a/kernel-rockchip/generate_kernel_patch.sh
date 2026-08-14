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
# 重要: 采用经典 quilt 统一 diff 格式(不带 diff --git / index 头)。
#   OpenWrt 的 patch 工具链(git apply / patch -p1)会把带
#   "index 000000000..000000000" 的 Makefile 段误判为"新建文件",
#   而 Makefile 实际已存在 -> "Not deleting file ... as content differs" ->
#   Patch failed。故 Makefile 段只用 --- a/ + +++ b/ 经典格式。
#
# 输出统一用 LF(经 python3 写文件), 避免 Windows Git Bash 文本模式
# 把 LF 改写成 CRLF 导致 patch 带多余回车。
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

# 用 python 生成, 强制 LF, 杜绝 CRLF
# 注意: Windows 原生 python 不认 Git Bash 的 /d/... 挂载路径, 需转 Windows 绝对路径
SRC_WIN="$(cygpath -w "$SRC" 2>/dev/null || echo "$SRC")"
OUT_WIN="$(cygpath -w "$OUT" 2>/dev/null || echo "$OUT")"
python3 - "$SRC_WIN" "$OUT_WIN" <<'PY'
import sys, io
src, out = sys.argv[1], sys.argv[2]
raw = open(src, "rb").read().replace(b"\r\n", b"\n").replace(b"\r", b"\n")
lines = raw.decode("utf-8").split("\n")
while lines and lines[-1] == "":
    lines.pop()
n = len(lines)

buf = []
# 1) 新增 dts (经典 quilt 新建文件格式)
buf.append("--- /dev/null")
buf.append("+++ b/arch/arm64/boot/dts/rockchip/rk3588-jea-e88a.dts")
buf.append("@@ -0,0 +1,%d @@" % n)
for l in lines:
    buf.append("+" + l)
# 2) 修改内核 dts Makefile, 注册 jea-e88a dtb (经典 quilt 修改格式)
buf.append("")
buf.append("--- a/arch/arm64/boot/dts/rockchip/Makefile")
buf.append("+++ b/arch/arm64/boot/dts/rockchip/Makefile")
buf.append("@@ -105,2 +105,3 @@ dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3568-rock-3b.dtb")
buf.append(" dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3568-rock-3b.dtb")
buf.append(" dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3588-armsom-sige7.dtb")
buf.append("+dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3588-jea-e88a.dtb")

open(out, "wb").write(("\n".join(buf) + "\n").encode("utf-8"))
print("Generated: %s  (dts %d lines, 2 diff sections: dts + Makefile)" % (out, n))
PY
