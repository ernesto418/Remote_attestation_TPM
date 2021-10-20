#!/bin/sh -x

rm -f credential.blob ek.crt ek.pub ak.pub ak.name pcr quote sig qualification \
config.cfg binary_runtime_measurements authorization_signature PuK.credential AuthPuK.pem \
server_pubkey.ctx end_user.ctx server_pubkey.name AESkey.credential AESkey.bin \
AuthPuK_encrypted.b64 auth.ctx auth.name auth.pub authorized.policy session.ctx certSig.out \
SeK.* SeKcert.out ../certificates/ucsr.bin auth_sign_bin sig.SeK

cp ../config.cfg ./config.cfg
#Creating primary here? is it no also in 4_KCV? to be checked
tpm2_createprimary -C o -g sha256 -G ecc256 -c end_user.ctx
