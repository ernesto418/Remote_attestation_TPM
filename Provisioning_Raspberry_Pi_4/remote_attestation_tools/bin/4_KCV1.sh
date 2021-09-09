#!/bin/sh -x

#Load public key 
echo Load public key 
tpm2_loadexternal -G rsa -C o -u PuK.pem -c server_pubkey.ctx -n server_pubkey.name

#Create authorization session with the public key
echo Create authorization session with the public key
tpm2_startauthsession -S session.ctx

tpm2_policyauthorize -S session.ctx -L authorized.policy -n server_pubkey.name

tpm2_flushcontext session.ctx

#We create the RSA key pair under the authorization policy 
echo We create the RSA key pair under the authorization policy (Sealed Key)
tpm2_create -G rsa -u SeK.pub -r Sek.priv -L authorized.policy -c Sek.ctx -C end_user.ctx


# Send SeK public key
./KCV_1
