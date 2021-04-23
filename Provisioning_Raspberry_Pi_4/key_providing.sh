#!/usr/bin/env bash
##TPM providing
echo "Creating keys"
cd remote_attestation_tools
sudo chmod a+rw /dev/tpm0
sudo chmod a+rw /dev/tpmrm0
#Warning: clear the platform hierarchy authorization values!
tpm2_clear -c p
tpm2_createek -G rsa -u ek.pub -c ek.ctx
tpm2_evictcontrol -C o -c ek.ctx 0x81010001
tpm2_createak -C 0x81010001 -c ak.ctx -G rsa -g sha256 -s rsassa -u ak.pub -n ak.name
tpm2_evictcontrol -C o -c ak.ctx 0x81000002

echo "Keys created"
