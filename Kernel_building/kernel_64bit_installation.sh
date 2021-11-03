#!/usr/bin/env bash

BNAME=${1?Error: no boot name given}
RNAME=${2?Error: no rootfs name given}
echo "boot name =  $BNAME and  rootfs name = $RNAME"
sudo umount /dev/$BNAME
sudo umount /dev/$RNAME
set -e
#Check the correct state of the sd card
echo "Testing SD card state"
mkdir mnt_test
mkdir mnt_test/fat32
mkdir mnt_test/ext4
sudo mount /dev/$BNAME mnt_test/fat32
sudo mount /dev/$RNAME mnt_test/ext4
sudo umount /dev/$BNAME
sudo umount /dev/$RNAME
sudo rm -r mnt_test
echo "SD card tested"

echo "Starting installation for Raspberry-pi 4"
#Computer dependencies (maybe needed)
    #sudo apt install crossbuild-essential-arm64

#Environment Variables
export PATH=$PATH:~/tools/arm-bcm2708/arm-linux-gnueabihf/bin
KERNEL=kernel8

#Download kernel
git clone -b rpi-4.19.y https://github.com/raspberrypi/linux
cd linux
git checkout 06606627043f72d22881563d485268fec2acd56d

#First installation
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcm2711_defconfig
make -j$(nproc) ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image modules dtbs
mkdir mnt
mkdir mnt/fat32
mkdir mnt/ext4

sudo mount /dev/$BNAME mnt/fat32
sudo mount /dev/$RNAME mnt/ext4

sudo env PATH=$PATH make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_MOD_PATH=mnt/ext4 modules_install
sudo cp mnt/fat32/$KERNEL.img mnt/fat32/$KERNEL-backup.img
sudo cp arch/arm64/boot/Image mnt/fat32/$KERNEL.img
sudo cp arch/arm64/boot/dts/broadcom/*.dtb mnt/fat32/
sudo cp arch/arm64/boot/dts/overlays/*.dtb* mnt/fat32/overlays/
sudo cp arch/arm64/boot/dts/overlays/README mnt/fat32/overlays/
sudo umount mnt/fat32
sudo umount mnt/ext4

#Adding parchs
sudo cp ../parch_64/clk-bcm2835.c drivers/clk/bcm/clk-bcm2835.c
sudo cp ../parch_64/.config .config
#sudo cp ../parch_64/ima_policy_v2.c security/integrity/ima/ima_policy.c
sudo cp ../parch_64/ima_policy.c security/integrity/ima/ima_policy.c

#Second installation
make -j$(nproc) ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image modules dtbs

sudo mount /dev/$BNAME mnt/fat32
sudo mount /dev/$RNAME mnt/ext4

sudo env PATH=$PATH make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_MOD_PATH=mnt/ext4 modules_install
sudo cp mnt/fat32/$KERNEL.img mnt/fat32/$KERNEL-backup.img
sudo cp arch/arm64/boot/Image mnt/fat32/$KERNEL.img
sudo cp arch/arm64/boot/dts/broadcom/*.dtb mnt/fat32/
sudo cp arch/arm64/boot/dts/overlays/*.dtb* mnt/fat32/overlays/
sudo cp arch/arm64/boot/dts/overlays/README mnt/fat32/overlays/
sudo umount mnt/fat32
sudo umount mnt/ext4

echo "Finished"
