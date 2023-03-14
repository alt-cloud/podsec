#!/bin/sh 
if [ $# -lt 2 ]
then
  echo "Формат вызова: $0 <пользователь> <группа1> ..."
  exit 1
fi
user=$1
shift
groups=
for group
do
        groups="$groups/O=$group"
done

openssl genrsa -out $user.key 2048
openssl req -new -key $user.key -out $user.csr -subj "/CN=$user$groups"
