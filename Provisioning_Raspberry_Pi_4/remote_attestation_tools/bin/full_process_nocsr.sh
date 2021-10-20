#!/bin/sh -x
set -e
echo ---------------- 0 ------------------
echo 
sh 0_prep.sh
echo --------------- 1 -----------------
echo
sh 1_cleanup.sh
echo ---------------- 2 ------------------
echo 
sh 2_pcr.sh
echo ----------------- 3 -------------------
echo 
sh 3_attune.sh
echo ------------------ 4 ------------------
echo
sh 4_KCV.sh
echo ----------------- 5 --------------------
echo
sh 5_atelic.sh
echo ------------------ 6 -------------------
echo 
sh 6_credential.sh
echo ------------------ 7 ---------------------
echo
sh 7_quote.sh
echo ------------------ 8 ---------------------
echo
sh 8_attest.sh

