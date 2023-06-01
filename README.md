# PODSEC (Podman Security)

`podsec` - набор скриптов для разворачивания и поддержки защищенных `rootless` решений для `podman` и `rootless-kubernetes` (`podsec-u7s`)  в рамках дистрибутивов `c10+`, `p10+` `ALTLinux`.


Обеспечивает:

- Создание пользователей различных категорий  с различными правами доступа и работы с docker-образами.

- Создание регистратора образов и WEB-сервера доступа к подписям образов

- Настройку политик доступа и работы с образами для различных категорий пользователей

- Разворачивание `rootfull` или `rootless` кластера `kubernetes` версии `v1.26.3` и выше на основе регистратора `registry.altlinux.org`

- Предоставление пользователям доступа к kubernetes-кластеру

- Настройку RBAC-правил доступа к кластеру kubernetes

## Категории пользователей

Пользователи делятся на следующие категории:

- Администраторы  - пользователя, входящие в группу `whell` включая root.

- Администратор `rootless kubernetes` - `u7s-admin`.

- Создателей `docker-образов`

- Пользователей `docker-образов`

### Администраторы

Эта категория пользователей имеет право создавать пользователей категории *создателей* и *пользователей* `docker-образов`.

Кроме этого при создании кластера kubernetes они имеют право администрировать кластер.

### Администратор rootless kubernetes - u7s-admin

Этот пользователь принадлежит системным пользователям.
Не входит в группу `wheel`. С точки зрения системы является обычным (непривелигрованным) пользователем.
От его имени (под его `uid`) и в рамках его `namespace` запускаются все `Pod`'ы в `rootless kubernetes-кластере`.

Как и `Администратор` имеет право администрировать `rootless` `kubernetes-кластер`.
Но в отличие от него, позволяет войти в его `namespace` и администрировать в рамках узла ресурсы этого `namespace`:
- сетевые интерфейсы `tap0`, `cni0`, ...;
- правила `iptables`;
- файлы и каталоги созданные в рамках этого `namespace`;
- процессы;
- ...

Кроме этого позволяет просматривать логи `Pod`ов узла в каталоге `/var/log/pods/...`


### Создатели docker-образов

Пользователи этой категории имеют все права по работе с образами:

- Скачивать образы с любого доступного регистратора.

- Импорт/Экспорт образов из архивных форматов.

- Создание образов из `Dockefile`'s.

- Помещение образов на регистраторы.

- Помещение с подписыванием свой электронной подписью образов на локальный регистратор `registry.local`

Пользователи входят в группы `podman-dev`, `podman`.

### Пользователи docker-образов

Пользователи этой категории не имеют ни одного из вышеперечисленных прав работы с образами, за исключением загрузки подписанных образов с локального регистратора `registry.local` и работы с ними.

Пользователи входят в группы `podman`.

## Набор RPM-пакетов

Файл спецификации `podsec.spec` обеспечивает создание следующих `RPM-пакетов`:

- `podsec` - набор скриптов по созданию пользователей, политик доступа, разворачивания локального регистратора и WEB-сервера подписей, загрузки архива kubernetes-образов в локальный регистратор.

- `podsec-k8s` - набор скриптов по разворачиванию rootless кластера `kubernetes`

- `podsec-k8s-rbac` - набор скриптов по предоставлению пользователям доступа к `kubernetes-кластеру` и назначения им ролей в рамках кластера.

- `podsec-inotify` - набор скриптов по мониторингу нарушения политик безопасности.

- `podsec-dev` - набор скриптов по уcтановке и обновлению `kubernetes-образов`.



## Замечания

- пакеты `podsec*` работает под `Linux kernel` версии `5.15` и выше.