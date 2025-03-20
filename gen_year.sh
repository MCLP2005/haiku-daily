#!/bin/bash
mkdir $1
cd $1
../../openai-o3-mini.sh 01-january.md "Write a haiku about every day of january ${1}."
../../openai-o3-mini.sh 02-february.md "Write a haiku about every day of february ${1}."
../../openai-o3-mini.sh 03-march.md "Write a haiku about every day of march ${1}."
../../openai-o3-mini.sh 04-april.md "Write a haiku about every day of april ${1}."
../../openai-o3-mini.sh 05-may.md "Write a haiku about every day of may ${1}."
../../openai-o3-mini.sh 06-june.md "Write a haiku about every day of june ${1}."
../../openai-o3-mini.sh 07-july.md "Write a haiku about every day of july ${1}."
../../openai-o3-mini.sh 08-august.md "Write a haiku about every day of august ${1}."
../../openai-o3-mini.sh 09-september.md "Write a haiku about every day of september ${1}."
../../openai-o3-mini.sh 10-october.md "Write a haiku about every day of october ${1}."
../../openai-o3-mini.sh 11-november.md "Write a haiku about every day of november ${1}."
../../openai-o3-mini.sh 12-december.md "Write a haiku about every day of december ${1}."

rm -rf logs

# git part

git add 01-january.md 02-february.md 03-march.md 04-april.md 05-may.md 06-june.md 07-july.md 08-august.md 09-september.md 10-october.md 11-november.md 12-december.md
git commit -S -m "Added haiku text files for the year ${1}"
git push

cd ..
