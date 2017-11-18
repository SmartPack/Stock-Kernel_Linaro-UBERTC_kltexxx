#!/bin/bash

COLOR_RED="\033[0;31m"
COLOR_GREEN="\033[1;32m"
COLOR_NEUTRAL="\033[0m"

echo -e $COLOR_GREEN"\n Stock-Kernel Build Script\n"$COLOR_NEUTRAL
#
echo -e $COLOR_GREEN"\n (c) sunilpaulmathew@xda-developers.com\n"$COLOR_NEUTRAL

# Toolchains

GOOGLE="/home/sunil/android-ndk-r15c/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin/arm-linux-androideabi-"

UBERTC="/home/sunil/UBERTC-arm-eabi-8.0/bin/arm-linux-androideabi-"

LINARO="/home/sunil/arm-linux-androideabi-7.x-linaro/bin/arm-linaro-linux-androideabi-"

TOOLCHAIN="linaro"	# Leave empty for using Google’s stock toolchain

ARCHITECTURE="arm"

KERNEL_NAME="Stock-Kernel"

KERNEL_VARIANT="kltekor"	# only one variant at a time

KERNEL_VERSION="v1-Linaro-7.2"   # leave as such, if no specific version tag

KERNEL_DATE="$(date +"%Y%m%d")"

COMPILE_DTB="y"

NUM_CPUS=""   # number of cpu cores used for build (leave empty for auto detection)

export ARCH=$ARCHITECTURE

if [ -z "$TOOLCHAIN" ]; then
	echo -e $COLOR_GREEN"\n building $KERNEL_NAME v. $KERNEL_VERSION for $KERNEL_VARIANT using Google's stock toolchain\n"$COLOR_NEUTRAL
	export CROSS_COMPILE="${CCACHE} $GOOGLE"
else
	if [ "ubertc" == "$TOOLCHAIN" ]; then
	echo -e $COLOR_GREEN"\n building $KERNEL_NAME v. $KERNEL_VERSION for $KERNEL_VARIANT using UBERTC-8.x\n"$COLOR_NEUTRAL
		export CROSS_COMPILE="${CCACHE} $UBERTC"
	else
		if [ "linaro" == "$TOOLCHAIN" ]; then
		echo -e $COLOR_GREEN"\n building $KERNEL_NAME v. $KERNEL_VERSION for $KERNEL_VARIANT using Linaro-7.x toolchain\n"$COLOR_NEUTRAL
			export CROSS_COMPILE="${CCACHE} $LINARO"
		fi
	fi
fi

if [ -z "$NUM_CPUS" ]; then
	NUM_CPUS=`grep -c ^processor /proc/cpuinfo`
fi

if [ -z "$KERNEL_VARIANT" ]; then
	echo -e $COLOR_GREEN"\n Please select the variant to build... KERNEL_VARIANT should not be empty...\n"$COLOR_NEUTRAL
fi

if [ "klte" == "$KERNEL_VARIANT" ]; then
	# creating backups
	cp scripts/mkcompile_h release/
	cp arch/arm/configs/lineage_klte_defconfig release/
	# updating kernel name
	sed -i "s;Stock-Kernel;$KERNEL_NAME-$KERNEL_VARIANT;" scripts/mkcompile_h;
	# updating kernel version
	sed -i "s;lineageos;$KERNEL_VERSION;" arch/arm/configs/lineage_klte_defconfig;
	if [ -e output_eur-$TOOLCHAIN/.config ]; then
		rm -f output_eur-$TOOLCHAIN/.config
		if [ -e output_eur-$TOOLCHAIN/arch/arm/boot/zImage ]; then
			rm -f output_eur-$TOOLCHAIN/arch/arm/boot/zImage
		fi
	else
		mkdir output_eur-$TOOLCHAIN
	fi
	make -C $(pwd) O=output_eur-$TOOLCHAIN lineage_klte_defconfig && make -j$NUM_CPUS -C $(pwd) O=output_eur-$TOOLCHAIN
	if [ -e output_eur-$TOOLCHAIN/arch/arm/boot/zImage ]; then
		echo -e $COLOR_GREEN"\n copying zImage to anykernel directory\n"$COLOR_NEUTRAL
		cp output_eur-$TOOLCHAIN/arch/arm/boot/zImage anykernel/
		# compile dtb if required
		if [ "y" == "$COMPILE_DTB" ]; then
			echo -e $COLOR_GREEN"\n compiling device tree blob (dtb)\n"$COLOR_NEUTRAL
			if [ -f output_eur-$TOOLCHAIN/arch/arm/boot/dt.img ]; then
				rm -f output_eur-$TOOLCHAIN/arch/arm/boot/dt.img
			fi
			chmod 777 tools/dtbToolCM
			tools/dtbToolCM -2 -o output_eur-$TOOLCHAIN/arch/arm/boot/dt.img -s 2048 -p output_eur-$TOOLCHAIN/scripts/dtc/ output_eur-$TOOLCHAIN/arch/arm/boot/
			# removing old dtb (if any)
			if [ -f anykernel/dtb ]; then
				rm -f anykernel/dtb
			fi
			# copying generated dtb to anykernel directory
			if [ -e output_eur-$TOOLCHAIN/arch/arm/boot/dt.img ]; then
				mv -f output_eur-$TOOLCHAIN/arch/arm/boot/dt.img anykernel/dtb
			fi
		fi
		echo -e $COLOR_GREEN"\n generating recovery flashable zip file\n"$COLOR_NEUTRAL
		cd anykernel/ && zip -r9 $KERNEL_NAME-$KERNEL_VARIANT-$KERNEL_VERSION-$KERNEL_DATE.zip * -x README.md $KERNEL_NAME-$KERNEL_VARIANT-$KERNEL_VERSION-$KERNEL_DATE.zip && cd ..
		echo -e $COLOR_GREEN"\n cleaning...\n"$COLOR_NEUTRAL
		rm anykernel/zImage && mv anykernel/$KERNEL_NAME* release/
		if [ -f anykernel/dtb ]; then
			rm -f anykernel/dtb
		fi
		# restoring backups
		mv release/mkcompile_h scripts/
		mv release/lineage_klte_defconfig arch/arm/configs/
		echo -e $COLOR_GREEN"\n everything done... please visit "release"...\n"$COLOR_NEUTRAL
	else
		if [ -f anykernel/dtb ]; then
			rm -f anykernel/dtb
		fi
		# restoring backups
		mv release/mkcompile_h scripts/
		mv release/lineage_klte_defconfig arch/arm/configs/
		echo -e $COLOR_GREEN"\n Building error... zImage not found...\n"$COLOR_NEUTRAL
	fi
fi

if [ "kltekor" == "$KERNEL_VARIANT" ]; then
	# creating backups
	cp scripts/mkcompile_h release/
	cp arch/arm/configs/lineage_kltekor_defconfig release/
	# updating kernel name
	sed -i "s;Stock-Kernel;$KERNEL_NAME-$KERNEL_VARIANT;" scripts/mkcompile_h;
	# updating kernel version
	sed -i "s;lineageos;$KERNEL_VERSION;" arch/arm/configs/lineage_kltekor_defconfig;
	if [ -e output_kor-$TOOLCHAIN/.config ]; then
		rm -f output_kor-$TOOLCHAIN/.config
		if [ -e output_kor-$TOOLCHAIN/arch/arm/boot/zImage ]; then
			rm -f output_kor-$TOOLCHAIN/arch/arm/boot/zImage
		fi
	else
		mkdir output_kor-$TOOLCHAIN
	fi
	make -C $(pwd) O=output_kor-$TOOLCHAIN lineage_kltekor_defconfig && make -j$NUM_CPUS -C $(pwd) O=output_kor-$TOOLCHAIN
	if [ -e output_kor-$TOOLCHAIN/arch/arm/boot/zImage ]; then
		echo -e $COLOR_GREEN"\n copying zImage to anykernel directory\n"$COLOR_NEUTRAL
		cp output_kor-$TOOLCHAIN/arch/arm/boot/zImage anykernel/
		# compile dtb if required
		if [ "y" == "$COMPILE_DTB" ]; then
			echo -e $COLOR_GREEN"\n compiling device tree blob (dtb)\n"$COLOR_NEUTRAL
			if [ -f output_kor-$TOOLCHAIN/arch/arm/boot/dt.img ]; then
				rm -f output_kor-$TOOLCHAIN/arch/arm/boot/dt.img
			fi
			chmod 777 tools/dtbToolCM
			tools/dtbToolCM -2 -o output_kor-$TOOLCHAIN/arch/arm/boot/dt.img -s 2048 -p output_kor-$TOOLCHAIN/scripts/dtc/ output_kor-$TOOLCHAIN/arch/arm/boot/
			# removing old dtb (if any)
			if [ -f anykernel/dtb ]; then
				rm -f anykernel/dtb
			fi
			# copying generated dtb to anykernel directory
			if [ -e output_kor-$TOOLCHAIN/arch/arm/boot/dt.img ]; then
				mv -f output_kor-$TOOLCHAIN/arch/arm/boot/dt.img anykernel/dtb
			fi
		fi
		echo -e $COLOR_GREEN"\n generating recovery flashable zip file\n"$COLOR_NEUTRAL
		cd anykernel/ && zip -r9 $KERNEL_NAME-$KERNEL_VARIANT-$KERNEL_VERSION-$KERNEL_DATE.zip * -x README.md $KERNEL_NAME-$KERNEL_VARIANT-$KERNEL_VERSION-$KERNEL_DATE.zip && cd ..
		echo -e $COLOR_GREEN"\n cleaning...\n"$COLOR_NEUTRAL
		rm anykernel/zImage && mv anykernel/$KERNEL_NAME* release/
		if [ -f anykernel/dtb ]; then
			rm -f anykernel/dtb
		fi
		# restoring backups
		mv release/mkcompile_h scripts/
		mv release/lineage_kltekor_defconfig arch/arm/configs/
		echo -e $COLOR_GREEN"\n everything done... please visit "release"...\n"$COLOR_NEUTRAL
	else
		if [ -f anykernel/dtb ]; then
			rm -f anykernel/dtb
		fi
		# restoring backups
		mv release/mkcompile_h scripts/
		mv release/lineage_kltekor_defconfig arch/arm/configs/
		echo -e $COLOR_GREEN"\n Building error... zImage not found...\n"$COLOR_NEUTRAL
	fi
fi
