
# Основные проблемы usernetes-решения

Основные проблемы usernetes-решения  две:

- некорректная работа RBAC. Поддержка Roles, ClusterRoles (хотя список ClusterRoles ограничивается только coredns), RoleBinding работает, но вновь созданный пользователь почему-то получает сразу ВСЕ права и RoleBinding оказывается как-бы не при делах

- разворачивание кластера идет без kubeadm путем создания для master и worker'ов общих томов куда складываются сертификаты. При запуске узел ждет когда общий сервис кластера cfssl сгенерирует сертификаты в общем томе. После этого запускает нужные для master или worker-узлов сервисы rootless kubernetes. Практически замена `kubeadm init`, `kubeadm join`.

Эта схема просто реализуется в `docker privrleged` режиме путем

* создания [docker-образа](https://gitea.basealt.ru/kaf/usernetes/src/branch/master/usernetes/Dockerfile) с необходимым функционалом

* написания [docker-compose.yml](https://gitea.basealt.ru/kaf/usernetes/src/branch/master/usernetes/docker-compose.yml)- файла.

Она позволяет:

* тестировать собранный образ путем разворачивания одно-узлового решения и запуске в нем Pod'ов [make test](https://gitea.basealt.ru/kaf/usernetes/src/branch/master/usernetes/Makefile#L22)

* разворачивать небольшой кластер из master-узла и двух worker-узлов [mae up](https://gitea.basealt.ru/kaf/usernetes/src/branch/master/usernetes/Makefile#L27)

Данная схема была использована для написания и отладки [собственного образа на основе ALTLinux p10](https://gitea.basealt.ru/kaf/usernetes/src/branch/master/README.md) с использованием пакетов kubernetes@p10 и образов (coredns, pause)

После отладки шаги [Dockerfile](https://gitea.basealt.ru/kaf/usernetes/src/branch/master/usernetes/Dockerfile) скриптом [fromDockerToScript.sh](https://gitea.basealt.ru/kaf/usernetes/src/branch/master/baremetal/fromDockerToScript.sh) переносились в скрипт [createUsernetes.sh](https://gitea.basealt.ru/kaf/usernetes/src/branch/master/usernetes/createUsernetes.sh), который использовался при [разворачивании rootless kuber в barematal-режиме](https://gitea.basealt.ru/kaf/usernetes/src/branch/master/INSTALL.md).

Разворачивание узла  производит скрипт [install.sh](https://gitea.basealt.ru/kaf/usernetes/src/branch/master/usernetes/install.sh), который

* генерирует пользовательские systemd `*.service` и `*.target` в systemd каталоге пользователя `~/.config/systemd/user/`

* генерирует

  * `.config/usernetes/containers/` - файлы политик

  * `.config/usernetes/crio/crio.conf` - файл конфигурации `crio`-сервиса

  * `.config/usernetes/env` - файл среды запуска

* запускает в зависимости от условий разворачивания (`singe master node`, `master + 2 workers`) пользовательские сервисы путем указания нужного `*.target` в `~/.config/systemd/user/`  путем вызова `systemctl --user -T start <target>`.


## Возможные пути решения проблем

Создание кластера путем выделения для разворачиваемых узлов общих томов куда помещаются сертификаты удобно при разворачивании кластера как [docker-сервисов](https://gitea.basealt.ru/kaf/usernetes/src/branch/master/usernetes/docker-compose.yml), но совершенно неприемлимо при `barematal`-разворачивании.

Кроме этого кластер разворачивается нестандартными механизмами и поддерживает усеченный функционал: отсутствие предопределенных ClusterRoles, некорректная работа RBAC, ...

Так что остается основной путь - разворачивание кластера стандартным через `kubeadm`.
`kubeadm` обеспечивает:

* инициализацию master-узла кластера (`kubeadm init`);

* генерацией сертификатов;

* команд подключения worker-узлов (`kubeadm join`);

* на `worker-узлах` подключение узла к кластеру путем вызова `kubeadm join`;

* генерацию и установку набора `ClusterRoles` (возможно это решит проблему некорректной работы этого механизмы в `usernetes`).

C 7.04.2023 по 9.04.2023 отлаженное решение [alt_usernetes](https://gitea.basealt.ru/kaf/usernetes) было перенесено в набор пакетов [podsec](https://github.com/alt-cloud/podsec/tree/master/usernetes).

Основные моменты переноса:

* так как разворачивание узла кластера производится от единственного пользователя узла обычный пользователь `user` был заменен на системного пользователя `u7s-admin`;

* основные файлы каталога [usernetes](https://github.com/alt-cloud/podsec/tree/master/usernetes) были включены в состав пакета [podsec-k8s](https://github.com/alt-cloud/podsec/tree/master/podsec-k8s);

* все файлы `*.service` и `*.target` каталога `~u7s-admin/.config/systemd/user/` перенесены в состав пакета `podsec-k8s`.

* в пакет `podsec-k8s` добавлен механизм создания пользователя `u7s-admin` и замены системного сервиса `kubelet` (см. ниже)

* в пакет `podsec-k8s` добавлены зависимости от всех необходимых для фкнкционирования kubernetes-пакетоа `ALT p10` (в `rootless-решении` основные `kubernetes` сервисы, за исключением `corednd` запускаются как обычные `systemd-сервисы` в среде пользователя `u7s-admin` в отличие от `rootfull-решения`, где основные сервисы за исключением `kubelet` разворачиваются в виде контейнеров).


При инициализации `master-узла` кластера (`kubeadm init`)  `kubeadm` требует наличие целого ряда условий, которые легко удовлетворить в `rootfull-окружении`, но проблематично в `rootless-окружении`:

1. наличие запущенного **системного** `kubelet` systemd-сервиса. `rootless kubelet` стартует не как системный сервис, а как пользовательский `systemd`-сервис (`systemctl --user ...`). Для решения этой проблемы можно переписать стандартный системный `systemd` `kubelet_сервис`, на системных `systemd сервис`, который запускает пользовательский [systemd kubelet_сервис](https://github.com/alt-cloud/podsec/blob/github/usernetes/services/kubelet.service) и перезапускает его в случае падения;

2. наличие файлов  конфигурации и сокетов `rootfull`-серсивов. Например для `rootfull crio` требуется наличие работающего сокета `/var/run/containerd/containerd.sock'.

3. и т. д.

Если часть проблем удастся решить путем подмены системных `rootfull` файлов конфигурации, то оставшуюся часть проблем придется решать путем модификации кода `kubeadm` и создания собственного `rootless kubeadm`.

