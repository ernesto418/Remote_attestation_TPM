
#!/bin/sh -x

cp /sys/kernel/security/ima/binary_runtime_measurements ./binary_runtime_measurements
./attest
sudo cat authorization_signature | base64 --decode > auth_sign_bin
