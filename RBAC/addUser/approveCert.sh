#!/bin/sh
if [ $# -ne 1 ]
then
  echo "Формат вызова: $0 <пользователь>"
  exit 1
fi
user=$1
# Подтверждение сертификата 
kubectl certificate approve $user
# Создание сертификата
kubectl get csr $user -o jsonpath='{.status.certificate}'| base64 -d > $user.crt
