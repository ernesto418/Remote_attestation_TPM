# creamos la signing authority
openssl genrsa -out signing_key_private.pem 2048

openssl rsa -in signing_key_private.pem -out signing_key_public.pem -pubout

tpm2_loadexternal -G rsa -C o -u signing_key_public.pem -c signing_key.ctx -n signing_key.name

# creamos la politica de autorizacion
tpm2_startauthsession -S session.ctx

tpm2_policyauthorize -S session.ctx -L authorized.policy -n signing_key.name

tpm2_flushcontext session.ctx

# get the reset value in a variable $reset
reset=$(tpm2_readclock | grep  reset_count: | grep -o  '[0-9]*')

# creamos policy digest
tpm2_startauthsession -S session.ctx

tpm2_policycountertimer -S session.ctx resets=$reset -L reset_cout.policy

tpm2_flushcontext session.ctx
 
# firmamos la politica
openssl dgst -sha256 -sign signing_key_private.pem -out reset_cout.signature reset_cout.policy

# creamos prim y secert to esconder
tpm2_createprimary -C o -g sha256 -G rsa -c prim.ctx

tpm2_create -g sha256 -u sealing_pubkey.pub -r sealing_prikey.pub -i- -C prim.ctx -L authorized.policy <<< "secret to seal"

tpm2_load -C prim.ctx -u sealing_pubkey.pub -r sealing_prikey.pub -c sealing_key.ctx

# verificamos la sesion 
tpm2_verifysignature -c signing_key.ctx -g sha256 -m reset_cout.policy -s reset_cout.signature -t verification.tkt -f rsassa

tpm2_startauthsession \--policy-session -S session.ctx

tpm2_policycountertimer -S session.ctx resets=$reset

tpm2_policyauthorize -S session.ctx -L authorized.policy -i reset_cout.policy -n signing_key.name -t verification.tkt

tpm2_unseal -p"session:session.ctx" -c sealing_key.ctx

tpm2_flushcontext session.ctx



# con firma 
tpm2_createprimary -C o -g sha256 -G rsa -c prim.ctx

tpm2_create -G rsa -u pubkey.pub -r prikey.pub -L authorized.policy -c rsa.ctx -C prim.ctx

echo "my message" > message.dat

# verificamos la sesion 

tpm2_startauthsession \--policy-session -S session.ctx

tpm2_policycountertimer -S session.ctx resets=$reset

tpm2_policyauthorize -S session.ctx -L authorized.policy -i reset_cout.policy -n signing_key.name -t verification.tkt

tpm2_sign -p"session:session.ctx" -c rsa.ctx -g sha256 -o sig.rssa message.dat

tpm2_verifysignature -c rsa.ctx -g sha256 -s sig.rssa -m message.dat

tpm2_flushcontext session.ctx


# Creamos el digest tpm2_policycountertimer
uint32: operandB
tpm2_policycountertimer -S  session.ctx -L policy.countertimer --eq resets=45
digest = sha1(operandB | 0010 | 0000)

digest = sha1(0000000000000000000000000000000000000000 | 0000016d | digest)

primer digest 0000002d00100000

segundo diges 00000000000000000000000000000000000000000000000000000000000000000000016dab1a225f806b7f50f21f2a687752c14b69ea449e33a90f7d12324332df630e9c

me quedo sin tiempo, averigua tu el resto ernesto, buena suerteeee
