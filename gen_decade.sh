#!/bin/bash
i=0
mkdir ${1}X
cd ${1}X/
while test $i -lt 10; do
  ../gen_year.sh ${1}${i}
  (( i++ ))
done
cd ..
