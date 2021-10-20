#!/bin/sh -x


#CSR debugg, Sealed key is no actually sealed

echo Signing Ucsr
echo  
tpm2_sign -c SeK.ctx -f plain -o ucsr.sign ../certificates/ucsr.bin
echo unsigned CSR signed: ucsr.sign



echo -------------- Sending Signature ----------------------------------
echo

# Send SeK public key
./CSR
