#!/bin/sh -x
# Exexute all the needed programs for an attestation
./attestation.sh
./first_attestation.sh
#2_pcr
tpm2_pcrread -o pcr
cp /sys/kernel/security/ima/binary_runtime_measurements ./binary_runtime_measurements

#3_attune
tpm2_readpublic -c 0x81000002 -o ak.pub
tpm2_nvread 0x1c00002 -o ek.crt

# Send AIK public key and expected PCRs value to server...
./attune

#To delete ./attune from the measurement digest list
#reboot

