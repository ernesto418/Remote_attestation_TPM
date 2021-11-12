#!/bin/sh -x


#Decrytp AESkey
echo Decrypting AESkey
echo  
tpm2_startauthsession --policy-session -S session.ctx
tpm2_policysecret -S session.ctx -c 0x4000000B
tpm2_activatecredential -c 0x81000002 -C 0x81010001 -i AESkey.credential -o AESkey.bin -P"session:session.ctx"
tpm2_flushcontext session.ctx
rm session.ctx

echo  
echo ----------------------------------------------------------------
#Using AESkey to decryt AuthPuK
echo
echo Decrypting Auth PuK "(AES decryption)"

./decrypt
echo
echo ----------------------------------------------------------------

#Load public key 
echo Loading Auth public key into the TPM
tpm2_loadexternal -G rsa -C o -u AuthPuK.pem -c auth.ctx -n auth.name
echo

#Create authorization session with the public key
echo Createing authorization policy with the public key
tpm2_startauthsession -S session.ctx

tpm2_policyauthorize -S session.ctx -L authorized.policy -n auth.name

tpm2_flushcontext session.ctx
echo
#We create the ECC key pair under the authorization policy in the owner hierarchy
echo Generating primary key in owner hierarchy
tpm2_createprimary -c end_user.ctx -C o -G ecc256

echo Creating and loading ECC-256 key pair under the authorization policy "(Sealed Key)"
tpm2_create -C end_user.ctx -G ecc256  -u SeK.pub -r SeK.priv -L authorized.policy -c SeK.ctx 
#echo Warning!!: Debug mode, not actually sealed key
#tpm2_create -C end_user.ctx -G ecc256  -u SeK.pub -r SeK.priv -c SeK.ctx

echo
#Certify the correct characteritics of Sealed key throught the atetstation key
echo Certifying key
tpm2_certify -C 0x81000002 -c SeK.ctx  -g sha256 -o SeKcert.out -s certSig.out

echo Sealed key certified":"
echo Attest: SeKcert.out
echo Signature: certSig.out
# Send SeK public key
./KCV
