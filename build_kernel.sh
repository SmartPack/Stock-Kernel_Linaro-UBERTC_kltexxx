#!/bin/bash

#
# SmartPack-Kernel Build Script
# 
# Author: sunilpaulmathew <sunil.kde@gmail.com>
#

#
# This script is licensed under the terms of the GNU General Public 
# License version 2, as published by the Free Software Foundation, 
# and may be copied, distributed, and modified under those terms.
#

#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#

#
# ***** ***** ***** ..How to use this script… ***** ***** ***** #
#
# For those who want to build this kernel using this script…
#
# Please note: this script is by-default designed to build only 
# one variants at a time.
#

# 1. Properly locate Stock, UBER & Linaro toolchains (Line# 44, 46 & 48)
# 2. Select the preferred toolchain for building (Line# 50)
# 3. Select the 'KERNEL_VARIANT' (Line# 56)
# 4. Open Terminal, ‘cd’ to the Kernel ‘root’ folder and run ‘. build_kernel.sh’
# 5. The output (anykernel zip) file will be generated in the ‘release’ folder
# 6. Enjoy your new Kernel

#
# ***** ***** *Variables to be configured manually* ***** ***** #
#

# Toolchains

GOOGLE="/home/sunil/android-ndk-r15c/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin/arm-linux-androideabi-"

UBERTC="/home/sunil/UBERTC-arm-eabi-8.2/bin/arm-none-eabi-"

LINARO="/home/sunil/arm-linux-androideabi-7.3-linaro/bin/arm-eabi-"

TOOLCHAIN="linaro"	# Leave empty for using Google’s stock toolchain

ARCHITECTURE="arm"

KERNEL_NAME="Stock-Kernel"

KERNEL_VARIANT="kltekor"	# only one variant at a time

KERNEL_DEFCONFIG="Stock_@$KERNEL_VARIANT@_defconfig"

KERNEL_VERSION="v9-Linaro-7.2"   # leave as such, if no specific version tag

KERNEL_DATE="$(date +"%Y%m%d")"

COMPILE_DTB="y"

PREPARE_RELEASE="y"

NUM_CPUS=""   # number of cpu cores used for build (leave empty for auto detection)

#
# ***** ***** ***** ***** ***THE END*** ***** ***** ***** ***** #
#

COLOR_RED="\033[0;31m"
COLOR_GREEN="\033[1;32m"
COLOR_NEUTRAL="\033[0m"

export ARCH=$ARCHITECTURE

if [ -z "$TOOLCHAIN" ]; then
	echo -e $COLOR_GREEN"\n building $KERNEL_NAME v. $KERNEL_VERSION for $KERNEL_VARIANT using Google's stock toolchain\n"$COLOR_NEUTRAL
	export CROSS_COMPILE="${CCACHE} $GOOGLE"
elif [ "ubertc" == "$TOOLCHAIN" ]; then
	echo -e $COLOR_GREEN"\n building $KERNEL_NAME v. $KERNEL_VERSION for $KERNEL_VARIANT using UBERTC-8.x\n"$COLOR_NEUTRAL
	export CROSS_COMPILE="${CCACHE} $UBERTC"
elif [ "linaro" == "$TOOLCHAIN" ]; then
	echo -e $COLOR_GREEN"\n building $KERNEL_NAME v. $KERNEL_VERSION for $KERNEL_VARIANT using Linaro-7.x toolchain\n"$COLOR_NEUTRAL
	export CROSS_COMPILE="${CCACHE} $LINARO"
fi

if [ -z "$NUM_CPUS" ]; then
	NUM_CPUS=`grep -c ^processor /proc/cpuinfo`
fi

if [ -z "$KERNEL_VARIANT" ]; then
	echo -e $COLOR_GREEN"\n Please select the variant to build... 'KERNEL_VARIANT' should not be empty...\n"$COLOR_NEUTRAL
else
	if [ -e arch/arm/configs/$KERNEL_DEFCONFIG ]; then
		# check and create release folder.
		if [ ! -d "release/" ]; then
			mkdir release/
		fi
		# creating backups
		cp scripts/mkcompile_h release/
		cp arch/arm/configs/$KERNEL_DEFCONFIG release/
		# updating kernel version
		sed -i "s;lineageos;$KERNEL_VERSION;" arch/arm/configs/$KERNEL_DEFCONFIG;
		if [ -e output_$KERNEL_VARIANT-$TOOLCHAIN/.config ]; then
			rm -f output_$KERNEL_VARIANT-$TOOLCHAIN/.config
			if [ -e output_$KERNEL_VARIANT-$TOOLCHAIN/arch/arm/boot/zImage ]; then
				rm -f output_$KERNEL_VARIANT-$TOOLCHAIN/arch/arm/boot/zImage
			fi
		else
			mkdir output_$KERNEL_VARIANT-$TOOLCHAIN
		fi
		make -C $(pwd) O=output_$KERNEL_VARIANT-$TOOLCHAIN $KERNEL_DEFCONFIG && make -j$NUM_CPUS -C $(pwd) O=output_$KERNEL_VARIANT-$TOOLCHAIN
		if [ -e output_$KERNEL_VARIANT-$TOOLCHAIN/arch/arm/boot/zImage ]; then
			echo -e $COLOR_GREEN"\n copying zImage to anykernel directory\n"$COLOR_NEUTRAL
			cp output_$KERNEL_VARIANT-$TOOLCHAIN/arch/arm/boot/zImage anykernel/
			# compile dtb if required
			if [ "y" == "$COMPILE_DTB" ]; then
				echo -e $COLOR_GREEN"\n compiling device tree blob (dtb)\n"$COLOR_NEUTRAL
				if [ -f output_$KERNEL_VARIANT-$TOOLCHAIN/arch/arm/boot/dt.img ]; then
					rm -f output_$KERNEL_VARIANT-$TOOLCHAIN/arch/arm/boot/dt.img
				fi
				chmod 777 tools/dtbToolCM
				tools/dtbToolCM -2 -o output_$KERNEL_VARIANT-$TOOLCHAIN/arch/arm/boot/dt.img -s 2048 -p output_$KERNEL_VARIANT-$TOOLCHAIN/scripts/dtc/ output_$KERNEL_VARIANT-$TOOLCHAIN/arch/arm/boot/
				# removing old dtb (if any)
				if [ -f anykernel/dtb ]; then
					rm -f anykernel/dtb
				fi
				# copying generated dtb to anykernel directory
				if [ -e output_$KERNEL_VARIANT-$TOOLCHAIN/arch/arm/boot/dt.img ]; then
					mv -f output_$KERNEL_VARIANT-$TOOLCHAIN/arch/arm/boot/dt.img anykernel/dtb
				fi
			fi
			echo -e $COLOR_GREEN"\n generating recovery flashable zip file\n"$COLOR_NEUTRAL
			cd anykernel/ && zip -r9 $KERNEL_NAME-$KERNEL_VARIANT-$KERNEL_VERSION-$KERNEL_DATE.zip * -x README.md $KERNEL_NAME-$KERNEL_VARIANT-$KERNEL_VERSION-$KERNEL_DATE.zip && cd ..
			echo -e $COLOR_GREEN"\n cleaning...\n"$COLOR_NEUTRAL
			rm anykernel/zImage && mv anykernel/$KERNEL_NAME* release/
			if [ -f anykernel/dtb ]; then
				rm -f anykernel/dtb
			fi
			if [ "y" == "$PREPARE_RELEASE" ]; then
				echo -e $COLOR_GREEN"\n Preparing for kernel release\n"$COLOR_NEUTRAL
				cp release/$KERNEL_NAME-$KERNEL_VARIANT-$KERNEL_VERSION-$KERNEL_DATE.zip kernel-release/$KERNEL_NAME-$KERNEL_VARIANT-$TOOLCHAIN.zip
			fi
			# restoring backups
			mv release/mkcompile_h scripts/
			mv release/$KERNEL_DEFCONFIG arch/arm/configs/
			echo -e $COLOR_GREEN"\n everything done... please visit "release"...\n"$COLOR_NEUTRAL
		else
			if [ -f anykernel/dtb ]; then
				rm -f anykernel/dtb
			fi
			# restoring backups
			mv release/mkcompile_h scripts/
			mv release/$KERNEL_DEFCONFIG arch/arm/configs/
			echo -e $COLOR_GREEN"\n Building error... zImage not found...\n"$COLOR_NEUTRAL
		fi
	else
		echo -e $COLOR_GREEN"\n '$KERNEL_VARIANT' is not a supported variant... please check...\n"$COLOR_NEUTRAL
	fi
fi
