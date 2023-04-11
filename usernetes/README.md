# Установка и настройка U7S (rootless kuber) по состоянию на 11.04.2023

1. Установите podsec-пакеты:
```
# apt-get install -y podsec-0.5.1-alt1.noarch.rpm      podsec-k8s-rbac-0.5.1-alt1.noarch.rpm podsec-k8s-0.5.1-alt1.noarch.rpm  podsec-nagios-plugins-0.5.1-alt1.noarch.rpm
```

2. Скачайте tar-архив `flannel_0.19.tgz`
<pre>
https://github.com/alt-cloud/podsec/blob/github/usernetes/flannel_0.19.tgz
</pre>

Разархивируйте его в  корневой каталог:
```
# tar xvzCf /  flannel_0.19.tgz
```
3. Скачайте tar-архив `cfssl.tgz`
https://github.com/alt-cloud/podsec/blob/github/usernetes/cfssl.tgz

Разархивируйте его в каталог `~u7s-admin/usernetes/`
```
# tar xvzCf ~u7s-admin/usernetes/ cfssl.tgz
```

4. Запустите команду:
```
# podsec-u7s-create-node
```

Задайте пароль пользователю `u7s-admin`


5. После завершения скрипта проверьте работу usernetes (rootless kuber)

```
# kubectl get all -A
```

6. Зайдите под пользователем `u7s-admin`

Проверьте работу usernetes (rootless kuber)

```
# kubectl get all -A
```
