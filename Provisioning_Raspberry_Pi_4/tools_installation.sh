#!/usr/bin/env bash
set -e
#Applying parches
sudo cp parch/config.txt /boot/config.txt
sudo cp parch/cmdline.txt /boot/cmdline.txt


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
#git checkout 2.4.0
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
#git checkout 4.2
./bootstrap
./configure
make -j$(nproc)
sudo make install
sudo ldconfig
cd ..

##TPM providing
echo "Creating keys"
cd remote_attestation_tools
sudo chmod a+rw /dev/tpm0
sudo chmod a+rw /dev/tpmrm0
tpm2_createek -G rsa -u ek.pub -c ek.ctx
tpm2_evictcontrol -C o -c ek.ctx 0x81010001
tpm2_createak -C 0x81010001 -c ak.ctx -G rsa -g sha256 -s rsassa -u ak.pub -n ak.name
tpm2_evictcontrol -C o -c ak.ctx 0x81000002
#If error in this step, try
    #code: tpm2_clear -c p
    #and execute this program again
    #Warning: you are clearing the TPM platfomr hierarchy!
echo "Keys created"

reboot


