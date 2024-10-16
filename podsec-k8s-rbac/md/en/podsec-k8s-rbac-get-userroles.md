podsec-k8s-rbac-get-userroles(1) -- get a list of cluster and regular user roles
=================================

## SYNOPSIS

`podsec-k8s-rbac-get-userroles username [showRules]`

## DESCRIPTION

The script generates a list of cluster and regular roles that are associated with the user.
When the `showRules` flag is specified, a list of rules ("rules:[...]") that belong to each user role is specified for each role.

The result is returned as a json string of the following format:
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

Where `[...]` is an array of objects of the type:
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

- [Generating certificates, creating workstations for the containerization tool security administrator, administrators of the information (automated) system and assigning them RBAC roles](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/README.md);

- [Description of the main classes of cluster roles (Roles, ClusterRoles) and mechanisms for binding them to subjects](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/rolesDescribe.md);

- [Configuring workstations for administrators of the information (automated) system (ClusterRole)](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/clusterroleBinding.md);

- [Configuring project administrator workstations (Role)](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/clusterroleBinding.md);

- [Configuring other roles](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/clusterroleBinding.md).

## AUTHOR

Kostarev Alexey, Basalt LLC
kaf@basealt.ru
