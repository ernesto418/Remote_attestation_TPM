#!/bin/sh -x

tpm2_readpublic -c 0x81000002 -o ak.pub
tpm2_nvread 0x1c00002 -o ek.crt

# Send AIK public key and expected PCRs value to server...
./attune

#Load public key 
echo Load public key 
tpm2_loadexternal -G rsa -C o -u PuK.pem -c server_pubkey.ctx -n server_pubkey.name

#Create authorization session with the public key
echo Create authorization session with the public key
tpm2_startauthsession -S session.ctx

tpm2_policyauthorize -S session.ctx -L authorized.policy -n server_pubkey.name

tpm2_flushcontext session.ctx

#We create the RSA key pair under the authorization policy 
echo We create the RSA key pair under the authorization policy 
tpm2_create -G rsa -u pubkey.pub -r prikey.pub -L authorized.policy -c rsa.ctx -C end_user.ctx

#This process is only valid if a CA create a certificate for this key pair created


