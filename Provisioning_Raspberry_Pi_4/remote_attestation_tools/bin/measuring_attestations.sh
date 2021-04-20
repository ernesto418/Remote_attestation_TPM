
#!/bin/sh -x
#1_cleanup
rm -f credential.blob ek.crt ek.pub ak.pub ak.name pcr quote sig qualification config.cfg binary_runtime_measurements
cp ../config.cfg ./config.cfg 
#7_Attest # we execute here the communication with the server to  get a fail and dont send a fake measure 
./attest

#2_pcr
tpm2_pcrread -o pcr
cp /sys/kernel/security/ima/binary_runtime_measurements ./binary_runtime_measurements
#4_attelic
tpm2_readpublic -c 0x81000002 -o ek.pub
./atelic
#5_credential
tpm2_startauthsession --policy-session -S session.ctx
tpm2_policysecret -S session.ctx -c 0x4000000B
tpm2_activatecredential -c 0x81000002 -C 0x81010001 -i credential.blob -o qualification -P"session:session.ctx"
tpm2_flushcontext session.ctx
rm session.ctx
#6_quote
echo "Remember to update pcr according to config.cfg"
pcrs="sha1:10+sha256:10"
qualification=`xxd -p -c 9999 qualification`
tpm2_quote -c 0x81000002 -q $qualification -l $pcrs  -m quote -s sig
