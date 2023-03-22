podsec-k8s-rbac-get-userroles(1) -- получить список кластерные и обычных ролей пользователя
================================

## SYNOPSIS

`podsec-k8s-rbac-get-userroles имя_пользователя [showRules]`

## DESCRIPTION

Скрипт формирует список кластерные и обычных ролей  которые связанв с пользователем.
При указании флага `showRules`, для каждой роли указывается список правил ("rules:[...]"), которые принадлежат каждой роли пользователя.

Результат возвращается в виде json-строки формата:
<pre>
{
  "<username>": {
    "clusterRoles": [...],
    "roles": {
      "allNamespaces": [...],
      "namespaces": [
        {
          "<namespace1>": [...],
          ...
        }
    }
  }
}
</pre>

Где `[...]` - массив объектов типа:
<pre>
{
  "bindRoleName": "<bindRoleName>",
  "bindedRoleType": "ClusterRole|Role",
  "bindedRoleName": "<bindedRoleName>",
  "unbindCmd": "podsec-k8s-rbac-unbindrole ..."
}
</pre>


## EXAMPLES

`podsec-k8s-rbac-get-userroles k8s-user1 | yq -y`
<pre>
k8s-user1:
  clusterRoles:
    - bindName: sysadmin
      roleType: ClusterRole
      roleName: edit
      unbindCmd: podsec-k8s-rbac-unbindrole k8s-user1 clusterrole edit sysadmin
    - bindName: sysview
      roleType: ClusterRole
      roleName: view
      unbindCmd: podsec-k8s-rbac-unbindrole k8s-user1 clusterrole view sysview
  roles:
    namespaces:
      - default:
          - bindName: basic-user
            roleType: ClusterRole
            roleName: system:basic-user
            unbindCmd: podsec-k8s-rbac-unbindrole k8s-user1 role system:basic-user
              basic-user default
          - bindName: sysadmin
            roleType: ClusterRole
            roleName: edit
            unbindCmd: podsec-k8s-rbac-unbindrole k8s-user1 role edit sysadmin default
      - smf:
          - bindName: basic-user
            roleType: ClusterRole
            roleName: system:basic-user
            unbindCmd: podsec-k8s-rbac-unbindrole k8s-user1 role system:basic-user
              basic-user smf
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
