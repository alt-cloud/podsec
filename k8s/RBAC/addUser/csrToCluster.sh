#!/bin/sh
if [ $# -ne 1 ]
then
  echo "Формат вызова: $0 <пользователь>"
  exit 1
fi
user=$1
request=$(base64 < $user.csr | tr -d "\n")
# Запись CSR в кластер
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: $user 
spec:
  request: $request
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 157680000  # 5 years
  usages:
  - client auth
EOF

