podsec-k8s-rbac-get-userroles(1) -- получить список кластерные и обычных ролей пользователя
================================

## SYNOPSIS

`podsec-k8s-rbac-get-userroles пользователь [showRules]`

## DESCRIPTION

Скрипт формирует список кластерные и обычных ролей  которые связанв с пользователем.
При указании флага `showRules`, для каждой роли указывается список правил ("rules:[...]"), которые принадлежат каждой роли пользователя.

Результат возвращается в виде json-строки формата:
```
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
```

Где `[...]` - массив объетов типа:
```
{
  "bindRoleName": "<bindRoleName>",
  "bindedRoleType": "ClusterRole|Role",
  "bindedRoleName": "<bindedRoleName>"
}

```

## EXAMPLES

`podsec-k8s-rbac-get-userroles k8s-user1 | yq -y`

```
k8s-user1:
  clusterRoles:
    - bindName: sysadmin
      roleType: ClusterRole
      roleName: edit
    - bindName: sysview
      roleType: ClusterRole
      roleName: view
  roles:
    allNamespaces:
      - bindName: sysview
        roleType: ClusterRole
        roleName: view
    namespaces:
      - default:
          - bindName: sysadmin
            roleType: ClusterRole
            roleName: edit
          - bindName: basic-user
            roleType: ClusterRole
            roleName: system:basic-user
      - smf:
          - bindName: basic-user
            roleType: ClusterRole
            roleName: system:basic-user

```

## SECURITY CONSIDERATIONS


