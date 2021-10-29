#!/usr/bin/env bash

BNAME=${1?Error: no boot name given}
RNAME=${2?Error: no rootfs name given}
echo "boot name =  $BNAME and  rootfs name = $RNAME"
sudo umount /dev/$BNAME
sudo umount /dev/$RNAME
set -e
#Check the correct state of the sd card
echo "Testing SD card state"
set +e
sudo rm -r mnt_test
set -e
mkdir mnt_test
mkdir mnt_test/fat32
mkdir mnt_test/ext4
sudo mount /dev/$BNAME mnt_test/fat32
sleep 1
sudo mount /dev/$RNAME mnt_test/ext4
sleep 2
sudo umount /dev/$BNAME
sudo umount /dev/$RNAME
sudo rm -r mnt_test
echo "SD card tested"

echo "Starting installation for Raspberry-pi 4"

#Environment Variables
export PATH=$PATH:~/tools/arm-bcm2708/arm-linux-gnueabihf/bin
KERNEL=kernel7l

#Download kernel
set  +e
sudo rm -r linux
set-e
sudo curl -L https://github.com/raspberrypi/linux/archive/06606627043f72d22881563d485268fec2acd56d.zip --output linux.zip
unzip linux.zip && mv linux-06606627043f72d22881563d485268fec2acd56d linux

#First installation

make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcm2711_defconfig
make -j$(nproc) ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage modules dtbs
mkdir mnt
mkdir mnt/fat32
mkdir mnt/ext4

sudo mount /dev/$BNAME mnt/fat32
sudo mount /dev/$RNAME mnt/ext4

sudo env PATH=$PATH make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=mnt/ext4 modules_install
sudo cp mnt/fat32/$KERNEL.img mnt/fat32/$KERNEL-backup.img
sudo cp arch/arm/boot/zImage mnt/fat32/$KERNEL.img
sudo cp arch/arm/boot/dts/*.dtb mnt/fat32/
sudo cp arch/arm/boot/dts/overlays/*.dtb* mnt/fat32/overlays/
sudo cp arch/arm/boot/dts/overlays/README mnt/fat32/overlays/
sudo umount mnt/fat32
sudo umount mnt/ext4

#Adding parchs
sudo cp ../parch/clk-bcm2835.c drivers/clk/bcm/clk-bcm2835.c
sudo cp ../parch/.config .config
sudo cp ../parch/ima_policy.c security/integrity/ima/ima_policy.c

#Second installation
make -j$(nproc) ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage modules dtbs

sudo mount /dev/$BNAME mnt/fat32
sudo mount /dev/$RNAME mnt/ext4

sudo env PATH=$PATH make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=mnt/ext4 modules_install
sudo cp mnt/fat32/$KERNEL.img mnt/fat32/$KERNEL-backup.img
sudo cp arch/arm/boot/zImage mnt/fat32/$KERNEL.img
sudo cp arch/arm/boot/dts/*.dtb mnt/fat32/
sudo cp arch/arm/boot/dts/overlays/*.dtb* mnt/fat32/overlays/
sudo cp arch/arm/boot/dts/overlays/README mnt/fat32/overlays/
sudo umount mnt/fat32
sudo umount mnt/ext4

echo "Finished"