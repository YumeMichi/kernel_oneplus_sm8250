#!/bin/bash

# Bash Color
green='\033[01;32m'
red='\033[01;31m'
blink_red='\033[05;31m'
restore='\033[0m'

clear

# Number of parallel jobs to run
THREAD="-j$(nproc)"

# AOSP clang 17.0.4 (https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/)
CLANG_BUILD="r498229b"

# Path to executables in LLVM toolchain
CLANG_BIN="/home/violet/toolchains/clang/clang-$CLANG_BUILD/bin"

# Environment
export PATH="$CLANG_BIN:$PATH"

# Vars
ARCH="arm64"
OS="14.0.0"
SPL="2024-01"
KDIR=`readlink -f .`
RAMFS=`readlink -f $KDIR/ramdisk`
OUT=`readlink -f $KDIR/out`

KMAKE_FLAGS=(
    -j"$(nproc)"
    ARCH="$ARCH"
    O="$OUT"

    LLVM=1
    LLVM_IAS=1

    CC="clang"
    CLANG_TRIPLE="aarch64-linux-gnu-"
)

# Kernel defconfig
DEFCONFIG="vendor/kona-perf_defconfig"

# Functions
function clean_all {
    echo
    git clean -fdx >/dev/null 2>&1
}

function make_kernel {
    clang -v
    make "${KMAKE_FLAGS[@]}" $DEFCONFIG savedefconfig
    make "${KMAKE_FLAGS[@]}"
}

function make_bootimg {
    echo "Making new boot image..."
    mkbootimg \
        --board kona \
        --kernel $OUT/arch/arm64/boot/Image \
        --ramdisk $RAMFS/ramdisk \
        --dtb $OUT/arch/arm64/boot/dtb \
        --cmdline "androidboot.console=ttyMSM0 androidboot.hardware=qcom androidboot.memcg=1 androidboot.usbcontroller=a600000.dwc3 cgroup.memory=nokmem,nosocket loop.max_part=7 lpm_levels.sleep_disabled=1 msm_rtb.filter=0x237 reboot=panic_warm service_locator.enable=1 swiotlb=2048 buildvariant=user" \
        --base 0x00000000 \
        --kernel_offset 0x00008000 \
        --ramdisk_offset 0x01000000 \
        --second_offset 0x00000000 \
        --tags_offset 0x00000100 \
        --dtb_offset 0x01f00000 \
        --os_version $OS \
        --os_patch_level $SPL \
        --pagesize 4096 \
        --header_version 2 \
        -o $OUT/boot.img
}

function flash_images {
    adb reboot fastboot >/dev/null 2>&1

    echo "Flashing kernel images..."
    sudo fastboot flash dtbo $OUT/arch/arm64/boot/dtbo.img
    sudo fastboot flash boot $OUT/boot.img

    sudo fastboot reboot
}

DATE_START=$(date +"%s")

echo -e "${green}"
echo "-----------------"
echo "Making Kernel:  "
echo "-----------------"
echo -e "${restore}"

echo

while read -p "Clean stuffs (y/n)? " cchoice
do
case "$cchoice" in
    y|Y )
        clean_all
        echo
        echo "All Cleaned now."
        break
        ;;
    n|N )
        break
        ;;
    * )
        echo
        echo "Invalid try again!"
        echo
        ;;
esac
done

echo

while read -p "Start building (y/n)? " dchoice
do
case "$dchoice" in
    y|Y )
        make_kernel || exit 1
        make_bootimg
        break
        ;;
    n|N )
        echo
        echo
        exit 1
        ;;
    * )
        echo
        echo "Invalid try again!"
        echo
        ;;
esac
done

echo

while read -p "Flash kernel images (y/n)? " dchoice
do
case "$dchoice" in
    y|Y )
        flash_images
        break
        ;;
    n|N )
        echo
        echo
        break
        ;;
    * )
        echo
        echo "Invalid try again!"
        echo
        ;;
esac
done

echo -e "${green}"
echo "-------------------"
echo "Build Completed in:"
echo "-------------------"
echo -e "${restore}"

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
echo
