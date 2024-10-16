podsec-k8s-rbac-bindrole(1) -- bind user to cluster or regular role
==================================

## SYNOPSIS

`podsec-k8s-rbac-bindrole username role|role=clusterrole|clusterrole role role_bind_name [namespace]`

## DESCRIPTION

The script binds a user to a regular or cluster role using role_bind_name.

## OPTIONS

- `username` must be created by `podsec-k8s-rbac-create-user` command and configured to access the cluster by `podsec-k8s-rbac-create-kubeconfig` command;

- `role type` can have the following values:

&nbsp;&nbsp;&nbsp;&nbsp;* `role` - the user is bound to a **regular role** named `<role>` (the `namespace` parameter is required in this case);

&nbsp;&nbsp;&nbsp;&nbsp;* `role=clusterrole` - the user is bound to a **regular role** using a **cluster role** named `<role>` (the `namespace` parameter is required in this case);

&nbsp;&nbsp;&nbsp;&nbsp;* `clusterrole` - the user is bound to a **cluster role** using a **cluster role** named `<role>` (the `namespace` parameter must be absent in this case).

- `role` - the name of a regular or cluster role depending on the previous parameter;

- `role_binding_name` - the name of the `rolebindings` or `clusterrolebindings` class object depending on the `role type` parameter. Within this object, several users can be bound to a cluster or regular role.

- `namespace` - the `namespace` name for a regular role.

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

- [Generating certificates, creating workstations for the containerization tool security administrator, administrators of the information (automated) system and assigning them RBAC roles](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/README.md);

- [Description of the main classes of cluster roles (Roles, ClusterRoles) and mechanisms for binding with subjects](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/rolesDescribe.md);

- [Configuring workstations of administrators of the information (automated) system (ClusterRole)](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/clusterroleBinding.md);

- [Configuring project administrator workstations (Role)](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/clusterroleBinding.md);

- [Configuring other roles](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/clusterroleBinding.md).

## AUTHOR

Kostarev Alexey, Basalt LLC
kaf@basealt.ru
