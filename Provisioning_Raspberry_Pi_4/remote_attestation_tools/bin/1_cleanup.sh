#!/bin/sh -x

rm -f credential.blob ek.crt ek.pub ak.pub ak.name pcr quote sig qualification \
config.cfg binary_runtime_measurements authorization_signature PuK.pem \
server_pubkey.ctx end_user.ctx server_pubkey.name
cp ../config.cfg ./config.cfg
tpm2_createprimary -C o -g sha256 -G ecc256 -c end_user.ctx
