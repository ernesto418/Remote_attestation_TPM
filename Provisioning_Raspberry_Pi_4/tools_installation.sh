#!/usr/bin/env bash
set -e
#Applying parches

sudo echo "dtparam=spi=on
dtoverlay=tpm-slb9670
" >> /boot/config.txt

cat /boot/cmdline.txt | tr --delete '\n' > middle
echo -n  " ima_policy=tcb" >> middle
sudo cp middle /boot/cmdline.txt
sudo rm middle

#Downloading tools

sudo apt update
sudo apt -y install autoconf-archive libcmocka0 libcmocka-dev procps iproute2 build-essential git pkg-config \
gcc libtool automake libssl-dev uthash-dev autoconf doxygen libgcrypt-dev libjson-c-dev libcurl4-gnutls-dev \
uuid-dev pandoc libconfig-dev libjson-c-dev libcurl4-gnutls-dev

##Remote_attestation-tools
set +e
mkdir /home/pi/tools
set -e
cp -r remote_attestation_tools /home/pi/tools/remote_attestation_tools
cd /home/pi/tools/remote_attestation_tools
make
cd ..


##TPM2-tss
set +e
git clone https://github.com/tpm2-software/tpm2-tss.git
set -e
cd tpm2-tss
git checkout 2.4.0
./bootstrap
./configure
make -j$(nproc)
sudo make install
sudo ldconfig
cd ..

##TPM2-tools
set +e
git clone https://github.com/tpm2-software/tpm2-tools.git
set -e
cd tpm2-tools
git checkout 4.2
./bootstrap
./configure
make -j$(nproc)
sudo make install
sudo ldconfig
cd ..

reboot
