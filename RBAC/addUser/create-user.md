# Создание рабочих мест и сертификатов

##  Копирование скриптов

```
$ mkdir ~/bin
$ cd ~/bin
```
копирование скриптов `createCSR.sh`, `csrToCluster.sh`, `approveCert.sh`, `checkCRT.sh`, `addToKubeconfig.sh` 
```
$ export PATH=$PATH:~/bin 
```

## Создание рабочего места 

Запишем имя создаваемого пользователя (например `user1`) в переменнуую `USER`:
```
$ export USER=user1
```
Создайте средствами `Linux` пользователя и задайте ему пароль:
```
$ sudo adduser $USER -g k8s
$ sudo passwd  $USER
```
Получите права пользователя создайте каталог .kube в домашнем директории пользователя:
```
$ export USERDIR=$(dirname $HOME)/$USER
$ export KUBECONFIGDIR=$USERDIR/.kube
$ sudo chmod 770 $USERDIR
$ sudo mkdir $KUBECONFIGDIR
$ sudo chmod 770 $KUBECONFIGDIR
$ sudo chown -R $USER:k8s $USERDIR 
$ cd $KUBECONFIGDIR 
```
Переменная `$KUBECONFIGDIR` хранит каталог, где располагается файл конфигурации `config` и формируемые ключи и сертификаты пользователя `$USER`.

## Создание сертификата пользователя и запись его в кластер 

**Ссылки**:
* [SSL/TLS: Форматы файлов криптографических ключей PEM](https://nsergey.com/ssl-tls-%D1%87%D1%82%D0%BE-%D1%82%D0%B0%D0%BA%D0%BE%D0%B5-%D1%84%D0%B0%D0%B9%D0%BB-pem/)

### Создание личного ключа и запроса на подпись сертификата - CSR (Certificate Signed Request)

При создании личного (`private`) ключа необходимо включить в него [информацию о пользователе и группе](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#x509-client-certs)  

Пример скрипта [createCSR.sh](createCSR.sh) :
```
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
```
Скрипту передается первым параметром имя пользователя, остальными список RBAC-групп в которых входит пользователь.
Все пользователи имеющие доступ в кластер должны иметь `RBAC-группу` `k8s`. Вторая RBAC-группа (`sysadmins`) определяет тип пользователя.
В данном случае `sysadmins` - группа **администратора информационной (автоматизированной) системы**.
После вызова:
```
$ createCSR.sh $USER k8s sysadmins
Generating RSA private key, 2048 bit long modulus (2 primes)
...
```
в каталоге конфигурации `.kube` пользователя появятся файлы:
* `$USER.key` - приватный ключ пользователя в формате `PEM`.
* `$USER.csr` - файл запроса на подпись сертификата (Certificate Signing Request).

**Ссылки**:
* [Create private key ](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/#create-private-key)
* [X509 Client Certs](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#x509-client-certs)

### Запись запроса на подпись сертификата (CSR) в кластер, его подтверждения и формирование сертификата (crt)

Запись запроса на подпись сертификата (`CSR`) в кластер обеспечивает скрипт [csrToCluster.sh](csrToCluster.sh):
```
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
```
Параметр `expirationSeconds` задает время действия сертификата.
Ее необходимо установить согласно политике обновления сертификатов в организации. 
Скрипт создает на основе  файла запроса подписи сертификата в кластере запись типа `CertificateSigningRequest`.

После вызова:
```
$ csrToCluster.sh $USER
certificatesigningrequest.certificates.k8s.io/$USER created
```
в кластере создастся запись типа `certificatesigningrequest.certificates.k8s.io`:
```
$ kubectl get certificatesigningrequest.certificates.k8s.io
NAME    AGE    SIGNERNAME                            REQUESTOR        REQUESTEDDURATION   CONDITION
$USER   2m5s   kubernetes.io/kube-apiserver-client   kubernetes-admin   5y                  Pending
```
в статусе `Pending`.
Файл запроса подписи сертификата можно удалить:
```
$ rm -f $USER.csr
```
Скрипт подтверждения сертификата: [approveCert.sh](approveCert.sh):
```
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
```
Функции создания и подписи сертификатов может принадлежать разным пользователям.
Но по условиям задания обе эти функции выполняет **администратор безопасности средства контейнеризации**.
После вызова:
```
$ approveCert.sh $USER
certificatesigningrequest.certificates.k8s.io/$USER approved
```
в каталоге конфигурации `.kube` пользователя появится файл сертификата `$USER.crt` в формате `PEM`.
В кластере соответствующая запись типа `certificatesigningrequest.certificates.k8s.io` получит статус `Approved,Issued`.
```
$ kubectl get certificatesigningrequest.certificates.k8s.io
NAME    AGE   SIGNERNAME                            REQUESTOR          REQUESTEDDURATION   CONDITION
$USER   14m   kubernetes.io/kube-apiserver-client   kubernetes-admin   5y                  Approved,Issued
```
Если по какой-то причине надо отказать в подписи запроса на сертификацию, наберите команду:
```
$ kubectl certificate deny $USER
```

**Ссылки**:
* [Create CertificateSigningRequest](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/#create-certificatesigningrequest) 
* [Create private key](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/#create-private-key)
* [Approve certificate signing request ](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/#approve-certificate-signing-request)

### Проверка сертификата

Вывод данных сертификата в текстовом виде:
```
$ openssl x509 -in $USER.crt -text -noout 
Certificate:
    Data:
        Version: 3 (0x2)
        ...
        Subject: O = k8s + O = sysadmins, CN = $USER
        ...
```
Для проверки соответствия сертификата приватному ключу запустите скрипт [checkCRT.sh](checkCRT.sh):
```
#!/bin/sh
if [ $# -ne 1 ]
then
  echo "Формат вызова: $0 <пользователь>"
  exit 1
fi
user=$1
openssl rsa  -noout -modulus -in $user.key | openssl md5
openssl x509 -noout -modulus -in $user.crt | openssl md5
```
После вызова 
```
$ checkCRT.sh $USER
```
результат вывода обоих команд должен совпадать:
```
(stdin)= 0daf77a8ad90b4f2a1822df5ddbec39e
(stdin)= 0daf77a8ad90b4f2a1822df5ddbec39e
```

**Ссылки**:
* [Some list of openssl commands for check and verify your keys ](https://gist.github.com/Hakky54/b30418b25215ad7d18f978bc0b448d81)

## Формирование файла конфигурации пользователя доступа к kubernetes  

Первоначально необходимо с сервера кластера скопировать файл `ca.crt` центра сертификации кластера (`certificate authority` - `CA`).
```
$ scp clusteradmin@<IP-адрес-кластера>:/etc/kubernetes/pki/ca.crt .
```

Формирование файла конфигурации пользователя `$USER` `.kube/config` обеспечивает скрипт [createKubeConfig.sh](createKubeConfig.sh):
```
#!/bin/sh
if [ $# -ne 1 ]
then
  echo "Формат вызова: $0 <пользователь>"
  exit 1
fi
user=$1
clustername=`kubectl config  view -o jsonpath='{.clusters[0].name}'`
clusterapi=`kubectl config  view -o jsonpath='{.clusters[0].cluster.server}'`

kubectl config set-cluster $clustername --certificate-authority=ca.crt --embed-certs=true --server=$clusterapi --kubeconfig=config
kubectl config set-credentials $user --client-certificate=$user.crt --client-key=$user.key --embed-certs=true --kubeconfig=config
kubectl config set-context default --cluster=$clustername --user=$user --kubeconfig=config
kubectl config use-context default --kubeconfig=config
```
После вызова скрипта:
```
$ createKubeConfig.sh $USER
Cluster "kubernetes" set.
User "$USER" set.
Context "default" created.
Switched to context "default".
```
в текущем каталоге сформируется файл конфигурации `config`:
```
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: 
...    
    server: <$clusterapi>
  name: <$clustername>
contexts:
- context:
    cluster: <$clustername>
    user: <$USER>
  name: default
current-context: default
kind: Config
preferences: {}
users:
- name: $USER
  user:
    client-certificate-data: 
...    
    client-key-data:   
...
```
**Ссылки**:
* [Add to kubeconfig](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/#add-to-kubeconfig)

## Проверка аутентификации пользователя kubernetes-сервером

Для проверки аутентификации пользователя `kubernetes-сервером` запустите команду:
```
$ clusterapi=`kubectl config  view -o jsonpath='{.clusters[0].cluster.server}'`
$ curl -s --key $USER.key --cert $USER.crt --cacert ca.crt  $clusterapi 
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "forbidden: User \"sysadmin\" cannot get path \"/\"",
  "reason": "Forbidden",
  "details": {},
  "code": 403
}
```
Имя пользователя в поле `message` должно совпадать с именем созданного пользователя.

Запрос к `$clusterapi/api` должен вернуть информацию о кластере:
```
$ curl -s --key $USER.key --cert $USER.crt --cacert ca.crt  $clusterapi/api
{
  "kind": "APIVersions",
  "versions": [
    "v1"
  ],
  "serverAddressByClientCIDRs": [
    {
      "clientCIDR": "0.0.0.0/0",
      "serverAddress": "<IP>:<port>"
    }
  ]
}
```

## Добавление контекста созданного пользователя 

Для добавления контекста созданного пользователя в конфигурацию **администратора безопасности средства контейнеризации** (текущий пользователь `securityadmin`) выполните скрипт [addContext.sh](addContext.sh):
```
#!/bin/sh
if [ $# -ne 1 ]
then
  echo "Формат вызова: $0 <пользователь>"
  exit 1
fi
user=$1

clustername=`kubectl config  view -o jsonpath='{.clusters[0].name}'`
kubectl config set-credentials $user --client-certificate=$user.crt --client-key=$user.key --embed-certs=true 
kubectl config set-context $user --cluster=$clustername --user=$user 
```

При вызове скрипта в файле конфигурации `~/.kube/config` администратора безопасности средства контейнеризации добавляется описание созданного пользователя, его открытые ключи и сертификаты.
```
$ addContext.sh $USER
User "$USER" set.
Context "$USER" created.
```

Проверьте наличие контекста созданного пользователя в списке вызовите команду:
```
$ kubectl config get-contexts
CURRENT   NAME                          CLUSTER      AUTHINFO           NAMESPACE
*         kubernetes-admin@kubernetes   kubernetes   kubernetes-admin   
...
          $USER                         kubernetes   ${USER}   
```
Переключитесь в контекст созданного пользователя:
```
$  kubectl config use-context $USER
Switched to context "$USER".
$ kubectl config get-contexts
CURRENT   NAME                          CLUSTER      AUTHINFO           NAMESPACE
          kubernetes-admin@kubernetes   kubernetes   kubernetes-admin   
...               
*         ${USER}                       kubernetes   ${USER} 
```
Проверьте аутентификацию созданного пользователя кластером:
```
$ kubectl get pods
Error from server (Forbidden): pods is forbidden: User "$USER" cannot list resource "pods" in API group "" in the namespace "default"
```
Имя пользователя в поле сообщении должно совпадать с именем созданного пользователя.

Вернитесь в контекст **администратора безопасности средства контейнеризации**:
```
$ kubectl config use-context kubernetes-admin@kubernetes
Switched to context "kubernetes-admin@kubernetes".
$ kubectl config get-contexts
CURRENT   NAME                          CLUSTER      AUTHINFO           NAMESPACE
*         kubernetes-admin@kubernetes   kubernetes   kubernetes-admin   
...               
```
Проверьте права доступа к списку pod'ов кластера в `namespace` `default`:
```
$ kubectl get pods
NAME   READY   STATUS    RESTARTS   AGE
...
```

## Восстановление прав доступа к файлам конфигурации созданного пользователя

В конце не забудьте ужесточить права доступа к файлам  конфигурации созданного пользователя:
```
$ cd ~
$ sudo chmod -R 700 $KUBECONFIGDIR
$ sudo chmod 700 $USERDIR
```
 
