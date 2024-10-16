podsec-k8s-rbac-unbindrole(1) -- unbind a user from a cluster or regular role
==================================

## SYNOPSIS

`podsec-k8s-rbac-unbindrole username role|clusterrole role role_bind_name [namespace]`

## DESCRIPTION

The script unbinds a role from a cluster or regular role created by the `podsec-k8s-rbac-bindrole` command. The full text of the command can be found in the output of the `podsec-k8s-rbac-get-userroles` command in the `unbindCmd` field. If the specified `role_bind_name` object of the `rolebindings` or `clusterrolebindings` class still contains users, the object is modified. If the list becomes empty, the object is deleted.

## OPTIONS

- `username` must be created by the `podsec-k8s-rbac-create-user` command and configured to access the cluster by the `podsec-k8s-rbac-create-kubeconfig` command;

- `role type` can have the following values:

&nbsp;&nbsp;&nbsp;&nbsp;* `role` - the user is bound to a **regular role** named `<role>` (the `namespace` parameter is required in this case);

&nbsp;&nbsp;&nbsp;&nbsp;* `clusterrole` - the user is bound to a **cluster role** using a **cluster role** named `<role>` (the `namespace` parameter must be absent in this case).

- `role` - the name of a regular or cluster role depending on the previous parameter;

- `role_binding_name` - the name of the `rolebindings` or `clusterrolebindings` class object depending on the `role type` parameter. Several users can be bound to a cluster or regular role within this object.

- `namespace` - the `namespace` name for a regular role.

## EXAMPLES

`podsec-k8s-rbac-unbindrole k8s-user1 clusterrole view sysview`

## SECURITY CONSIDERATIONS

## SEE ALSO

- [Generating certificates, creating workstations for a containerization tool security administrator, information (automated) system administrators, and assigning them RBAC roles](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/README.md);

- [Description of the main classes of cluster roles (Roles, ClusterRoles) and mechanisms for binding to subjects](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/rolesDescribe.md);

- [Configuring workstations of administrators of the information (automated) system (ClusterRole)](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/clusterroleBinding.md);

- [Configuring workstations of project administrators (Role)](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/clusterroleBinding.md);

- [Configuring other roles](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/clusterroleBinding.md).

## AUTHOR

Kostarev Alexey, Basealt LLC
kaf@basealt.ru
