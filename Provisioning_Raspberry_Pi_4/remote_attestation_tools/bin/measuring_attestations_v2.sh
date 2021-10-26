#!/bin/sh -x


echo ---------------- life work  ------------------
echo 
sudo ../../../myapplication.py

echo ---------------- 0 ------------------
echo 
sh 0_prep.sh

rm quote
# first to avoid send real attestation try getting an error becasue credential is not ready
echo ------------------ 8 ---------------------
echo
sh 8_attest.sh

echo ---------------- 2 ------------------
echo 
sh 2_pcr.sh

echo ----------------- 5 --------------------
echo
sh 5_atelic.sh
echo ------------------ 6 -------------------
echo 
sh 6_credential.sh
echo ------------------ 7 ---------------------
echo
sh 7_quote.sh


