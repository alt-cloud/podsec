podsec-k8s-rbac-create-user(1) -- создание RBAC-пользователя
================================

## SYNOPSIS

`podsec-k8s-rbac-create-user имя_пользователя`

## DESCRIPTION

Скрипт:

- создает RBAC пользователя

- создает в домашнем директории каталог .kube

- устанавливаются соответствующие права доступа к каталогам.

## EXAMPLES

`podsec-k8s-rbac-create-user k8s-user1`

## SECURITY CONSIDERATIONS

## SEE ALSO

- [Генерация сертификатов, создание рабочих мест администратора безопасности средства контейнеризации, администраторов информационной (автоматизированной) системы и назначение им RBAC-ролей](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/README.md);

- [Создание рабочих мест и сертификатов](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/clusterroleBinding.md).

## AUTHOR

Костарев Алексей, Базальт СПО
kaf@basealt.ru
