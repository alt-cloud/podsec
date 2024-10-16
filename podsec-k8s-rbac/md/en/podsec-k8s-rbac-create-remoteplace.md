podsec-k8s-rbac-create-remoteplace(1) -- create a remote workstation
=================================

## SYNOPSIS

`podsec-k8s-rbac-create-remoteplace ip-address`

## DESCRIPTION

The script configures the user's remote workstation by copying its configuration file.

## EXAMPLES

`podsec-k8s-rbac-create-remoteplace 192.168.122.234`

## SECURITY CONSIDERATIONS

To improve the security of working with the cluster, it makes sense to move user workstations to separate workstations.

The security administrator of the containerization tool copies the `.kube/config` configuration file to his workstation using this script and gets the ability to work remotely with the cluster.

When creating workstations, the containerization tool security administrator creates home directories and a configuration file `.kube/config` on his workstation using the scripts `podsec-k8s-rbac-create-user`, `podsec-k8s-rbac-create-kubeconfig`, `podsec-k8s-rbac-bindrole`, creating the context of the created user. By switching to the user context, the containerization tool security administrator can test the access rights of the created user.

The user copies the configuration file to himself on his remote workstation using this script.

The home directory of the created user on the containerization tool security administrator's workstation is deleted.

## SEE ALSO

- [Generating certificates, creating workstations for the containerization tool security administrator, administrators of the information (automated) system and assigning them RBAC roles](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/README.md);

- [Creating a workstation for the containerization tool security administrator](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/clusterroleBinding.md).

## AUTHOR

Kostarev Alexey, Basalt LLC
kaf@basealt.ru
