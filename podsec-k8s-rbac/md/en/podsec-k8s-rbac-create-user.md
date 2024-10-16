podsec-k8s-rbac-create-user(1) -- create RBAC user
==================================

## SYNOPSIS

`podsec-k8s-rbac-create-user username`

## DESCRIPTION

Script:

- creates RBAC user

- creates .kube directory in home directory

- sets appropriate access rights to directories.

## EXAMPLES

`podsec-k8s-rbac-create-user k8s-user1`

## SECURITY CONSIDERATIONS

## SEE ALSO

- [Generating certificates, creating workstations for the containerization tool security administrator, administrators of the information (automated) system and assigning them RBAC roles](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/README.md);

- [Creating workstations and certificates](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/clusterroleBinding.md).

## AUTHOR

Kostarev Alexey, Basealt LLC
kaf@basealt.ru
