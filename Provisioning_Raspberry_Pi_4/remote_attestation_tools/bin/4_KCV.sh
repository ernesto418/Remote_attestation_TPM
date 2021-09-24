#!/bin/sh -x


#Decrypting Auth public key showing that Ak.pub was valid
echo Decrypting Auth public key
tpm2_startauthsession --policy-session -S session.ctx
tpm2_policysecret -S session.ctx -c 0x4000000B
tpm2_activatecredential -c 0x81000002 -C 0x81010001 -i auth.secret -o auth.pem -P"session:session.ctx"
tpm2_flushcontext session.ctx
rm session.ctx


#Load public key 
echo Loading Auth public key into the TPM
tpm2_loadexternal -G rsa -C o -u auth.pem -c auth.ctx -n auth.name

#Create authorization session with the public key
echo Createing authorization policy with the public key
tpm2_startauthsession -S session.ctx

tpm2_policyauthorize -S session.ctx -L authorized.policy -n auth.name

tpm2_flushcontext session.ctx

#We create the ECC key pair under the authorization policy in the owner hierarchy
tpm2_createprimary -c end_user.ctx -C o 

echo Creating and loading ECC-256 key pair under the authorization policy (Sealed Key)
tpm2_create -C end_user.ctx -G ecc256  -u SeK.pub -r Sek.priv -L authorized.policy -c Sek.ctx 

#Certify the correct characteritics of Sealed key throught the atetstation key

tpm2_certify -C ak.ctx -c Sek.ctx  -g sha256 -o attest.out -s sig.out

# Send SeK public key
./KCV
