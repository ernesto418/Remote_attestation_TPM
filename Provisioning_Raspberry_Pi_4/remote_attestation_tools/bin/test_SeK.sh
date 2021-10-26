#!/bin/sh -x

echo "my message" > message.dat
reset=$(tpm2_readclock | grep reset_count: | grep -o '[0-9]*')
#Loading keys
tpm2_loadexternal -G rsa -C o -u AuthPuK.pem -c auth.ctx -n auth.name
tpm2_createprimary -c end_user.ctx -C o
tpm2_load -C end_user.ctx  -u SeK.pub -r SeK.priv -c SeK.ctx
# generating tpm2_Policypcr and tpm2_policycountertimer digest

tpm2_startauthsession -S session.ctx --hash-algorithm="sha256"

tpm2_policypcr -S session.ctx -l "sha256:10"
tpm2_policycountertimer -S session.ctx resets=$reset -L pcrreset_policy.digest

tpm2_flushcontext session.ctx

# Verifying authorization signature
echo "verifying signature"
tpm2_verifysignature -c auth.ctx -g sha256 -m pcrreset_policy.digest -s auth_sign_bin -t verification.tkt -f rsassa


# Start session
tpm2_startauthsession --policy-session -S session.ctx --hash-algorithm="sha256"

# Generate current policypcr and policyreset (Real!!)
echo "Satisfying policies"
tpm2_policypcr -S session.ctx -l "sha256:10"
tpm2_policycountertimer -S session.ctx resets=$reset

echo "policies satisfied"
# Demostrating that we have authorization to use our key in the current policypcr

tpm2_policyauthorize -S session.ctx -L authorized.policy -i pcrreset_policy.digest -n auth.name -t verification.tkt

# We use the Sealed key

tpm2_sign -p"session:session.ctx" -c SeK.ctx -g sha256 -o sig.SeK message.dat

tpm2_flushcontext session.ctx

# Verify signature

tpm2_verifysignature -c SeK.ctx -g sha256 -s sig.SeK -m message.dat
