# Создание рабочего места администратора безопасности средства контейнеризации 

Установите команду `kubectl` из пакета `kubernetes-client`:
```
# apt-get install kubernetes-client
```

Создайте средствами Linux группу `k8s` и  пользователя (например securityadmin) и задайте ему пароль:
```
# groupadd -r k8s
# adduser securityadmin -g k8s -G wheel
# passwd securityadmin
```
<!-- Зайдите в кластер под пользователем, созданным во время [создания кластера](https://www.altlinux.org/Kubernetes). 
Уточните в кластере IP-адрес кластера командой:
```
$ kubectl config view -o jsonpath='{.clusters[0].cluster.server}'
```
-->
Получите права пользователя `securityadmin` и создайте каталог `.kube`:
```
# su - securityadmin
$ mkdir -m 0700 .kube
```
Скопируйте файл, созданный в домашнем директории пользователя (например `clusteradmin`) во время [создания кластера](https://www.altlinux.org/Kubernetes):
```
$ scp clusteradmin@<IP-адрес-кластера>:~clusteradmin/.kube/config ~securityadmin/.kube/config
```
> Обратите особое внимание на защиту доступа к файлу ~clusteradmin/.kube/config. При его копировании сторонним пользователем  возможен неограниченный доступ к ресурсам кластера.

Проверьте доступ в кластер:
```
$ kubectl get nodes
NAME       STATUS   ROLES           AGE   VERSION
...        Ready    <none>          10d   v1.24.8
...
```







