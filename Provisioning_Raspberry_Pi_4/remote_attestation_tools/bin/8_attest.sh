

#!/bin/sh -x

cp /sys/kernel/security/ima/binary_runtime_measurements ./binary_runtime_measurements
./attest

set -e
sudo cat authorization_signature | base64 --decode > auth_sign_bin
rm authorization_signature
echo "Auth signature in binary writen in auth_sign_bin"
