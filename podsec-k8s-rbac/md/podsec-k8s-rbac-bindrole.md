podsec-k8s-rbac-bindrole(1) -- привязывание пользователя к кластерной или обычной роли
================================

## SYNOPSIS

`podsec-k8s-rbac-bindrole имя_пользователя role|role=clusterrole|clusterrole роль имя_связки_роли [namespace]`

## DESCRIPTION

Скрипт производит привязку пользователя к обычной или кластерной роли используя имя_связки_роли.

## OPTIONS

- `имя_пользователя` должно быть создано командой `podsec-k8s-rbac-create-user` и сконфигурировано на доступ к кластеру командой `podsec-k8s-rbac-create-kubeconfig`;

- `тип роли` может принимать следующие значения:

&nbsp;&nbsp;&nbsp;&nbsp;* `role` - пользователь привязывется к **обычной роли** с именем `<роль>` (параметр `namespace` в этом случае обязателен);

&nbsp;&nbsp;&nbsp;&nbsp;* `role=clusterrole` - пользователь привязывется к **обычной роли** используя **кластерную роль** с именем `<роль>` (параметр `namespace` в этом случае обязателен);

&nbsp;&nbsp;&nbsp;&nbsp;* `clusterrole` -  пользователь привязывется к **кластерной роли**  используя **кластерную роль** с именем `<роль>` (параметр `namespace` в этом случае должен отсутствовать).

- `роль` - имя обычной или кластерной роли в зависимости от предыдущего параметра;

- `имя_связки_роли` - имя объекта класса `rolebindings` или `clusterrolebindings` в зависимости от параметра `тип роли`. В рамках этого объекта к кластерной или обычной роли могут быть привязаны несколько пользователей.

- `namespace` - имя `namespace` для обычной роли.

## EXAMPLES

<pre>
podsec-k8s-rbac-bindrole k8s-user1 clusterrole edit sysadmin
podsec-k8s-rbac-bindrole k8s-user1 clusterrole view sysview
podsec-k8s-rbac-bindrole k8s-user1 role=clusterrole edit sysadmin default
podsec-k8s-rbac-bindrole k8s-user1 role=clusterrole system:basic-user basic-user default
podsec-k8s-rbac-bindrole k8s-user1 role=clusterrole system:basic-user basic-user smf
</pre>

## SECURITY CONSIDERATIONS

## SEE ALSO

- [Генерация сертификатов, создание рабочих мест администратора безопасности средства контейнеризации, администраторов информационной (автоматизированной) системы и назначение им RBAC-ролей](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/README.md);

- [Описание основных классов ролей кластера (Roles, ClusterRoles) и механизмов из связываения с субъектами](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/rolesDescribe.md);

- [Настройка рабочих мест администраторов информационной (автоматизированной) системы (ClusterRole)](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/clusterroleBinding.md);

- [Настройка рабочих мест администраторов проектов (Role)](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/clusterroleBinding.md);

- [Настройка других ролей](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/clusterroleBinding.md).

## AUTHOR

Костарев Алексей, Базальт СПО
kaf@basealt.ru
