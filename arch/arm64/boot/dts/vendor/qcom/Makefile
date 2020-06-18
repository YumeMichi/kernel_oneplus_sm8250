# SPDX-License-Identifier: GPL-2.0

ifeq ($(CONFIG_BUILD_ARM64_DT_OVERLAY),y)
	dtbo-$(CONFIG_ARCH_KONA) += \
		kona-mtp-overlay.dtbo

kona-mtp-overlay.dtbo-base := kona-v2.1.dtb
else
dtb-$(CONFIG_ARCH_KONA) += \
	kona-v2.1-mtp.dtb
endif

always		:= $(dtb-y)
subdir-y	:= $(dts-dirs)
clean-files    := *.dtb *.dtbo
