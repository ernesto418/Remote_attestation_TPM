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

# Con los valores de los archivos de bin

echo "my message" > message.dat

reset=$(tpm2_readclock | grep  reset_count: | grep -o  '[0-9]*')

tpm2_startauthsession -S session.ctx

tpm2_policycountertimer -S session.ctx resets=$reset -L reset_cout.policy

tpm2_flushcontext session.ctx

tpm2_verifysignature -c auth.ctx -g sha256 -m reset_cout.policy -s auth_sign_bin -t verification.tkt -f rsassa

tpm2_startauthsession --policy-session -S session.ctx

tpm2_policycountertimer -S session.ctx resets=$reset

tpm2_policyauthorize -S session.ctx -L authorized.policy -i reset_cout.policy -n auth.name -t verification.tkt

tpm2_sign -p"session:session.ctx" -c SeK.ctx -g sha256 -o sig.SeK message.dat

tpm2_verifysignature -c SeK.ctx -g sha256 -s sig.SeK -m message.dat

tpm2_flushcontext session.ctx



# Creamos el digest tpm2_policycountertimer
uint32: operandB

tpm2_policycountertimer -S  session.ctx -L policy.countertimer --eq resets=45

## IBM Examples:
Here we have operandB = time is 64 bits at offset 0 operandB = 0000000000000000:

Then we have kind of variable to measure, the time, Var_meas = 0000

Then we have the operation to compare,operation valriable OP_var = 0002

digest_1 = sha1(operandB | Var_meas | OP_var)

The final digest is:

digest = sha1(0000000000000000000000000000000000000000 | 0000016d | digest)

## Ernesto Examples:

We compare reser with value 45, and the comparation operation is "=", and we use sha256. T(he sice of reset is smoller thaht the size of time)

digest_1 = sha256(operandB | Var_meas | OP_var)
primer digest 0000002d00100000

digest = sha256(0000000000000000000000000000000000000000000000000000000000000000 | 0000016d | digest)


me quedo sin tiempo, espero que la explicacion este bien, aqui unas ubicaciones que te pueden venir bien:

policymaker.c

policycoutertimer.tst,

ibmtss1.6.0\utils\regtests\testpolicy.sh


# Creamos el digest tpm2_policyauthorized

In a trial session

tpm2_policyauthorize -S session.ctx -L authorized.policy -n signing_key.name

## IBM Examples:

We have first the comand TPM_CC_PolicyAuthorize = 0x0000016a

Then we have the key name keySign = 0x000b64ac921a035c72b3aa55ba7db8b599f1726f52ec2f682042fc0e0d29fae81799


digest_1 = sha256(Oldpolicy | command | keySign)

digest_1 = sha256(00000000000000000000000000000000000000000000000000000000000000000000016a000b64ac921a035c72b3aa55ba7db8b599f1726f52ec2f682042fc0e0d29fae81799)

-now we do a second hash:

Digest_final = sha256(digest_1);

# Creamos el digest tpm2_PolicyPCR

We have first the comand TPM_CC_PolicyPCR = 0x0000017F

Then we have our PCR value = 0xEB6F87E41B32FFA95AEFC3C6CADC4183FCFFCD60CF169AA98FB9D8D7B7B0626C

And finally, the Selected PCR array (array that reflect the selected PCR), it is a some complex system, but the important is that for PCR 10, the array is = 0x00000001000b03000400

Digest_1 = sha256(PCR value)

Digest_1 = sha256(EB6F87E41B32FFA95AEFC3C6CADC4183FCFFCD60CF169AA98FB9D8D7B7B0626C)

Diges_2 = sha256(Last_policy_digest||TPM_CC_PolicyPCR||Selected PCR array||Digest_1)

Diges_2 = sha256(L0000000000000000000000000000000000000000000000000000000000000000||0000017F||00000001000b03000400||8aff56b22cf2037433349f6619d7351784ac1fe896a573613f272e7109145c98)
