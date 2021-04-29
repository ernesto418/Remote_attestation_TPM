#!/bin/sh -x

echo "Obtaining the name of the policy for the current reset value"

reset=$(tpm2_readclock | grep reset_count: | grep -o '[0-9]*')

tpm2_startauthsession -S session.ctx
tpm2_policycountertimer -S session.ctx resets=$reset -L reset_cout.policy
tpm2_flushcontext session.ctx


echo "Verifying the authorization signed:"
tpm2_verifysignature -c server_pubkey.ctx -g sha256 -m reset_cout.policy -s auth_sign_bin -t verification.tkt -f rsassa

