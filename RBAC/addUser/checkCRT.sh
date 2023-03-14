#!/bin/sh
if [ $# -ne 1 ]
then
  echo "Формат вызова: $0 <пользователь>"
  exit 1
fi
user=$1
openssl rsa  -noout -modulus -in $user.key | openssl md5
openssl x509 -noout -modulus -in $user.crt | openssl md5
