podsec-k8s-rbac-create-kubeconfig(1) -- create keys, certificates, and RBAC user configuration file

## SYNOPSIS

`podsec-k8s-rbac-create-kubeconfig username[@<remote_username>] [group ...]`

## DESCRIPTION

The script should be called by the *containerization tool security administrator*.

For `rootless` solution, the remote user name is assumed to be `u7s-admin`.

For `rootfull` solution, the remote user name must be specified after the `@` symbol.

The script in the `~username/.kube` directory does the following:

- Create a private user key (file `username.key`).

- Create a certificate signing request (CSR) (file `username.key`).

- Write a CSR certificate signing request to the cluster.

- Confirm a certificate signing request (CSR).

- Create a certificate (file `username.crt`).

- Check the correctness of the certificate

- Generate a user configuration file (file `config`)

- Add the context of the created user

## EXAMPLES

`podsec-k8s-rbac-create-kubeconfig k8s-user1`

## SECURITY CONSIDERATIONS

## SEE ALSO

- [Generate certificates, create workstations for the containerization tool security administrator, administrators of the information (automated) system and assign them RBAC roles](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/README.md);

- [Creating workplaces and certificates](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/clusterroleBinding.md).

## AUTHOR

Kostarev Alexey, Basealt LLC
kaf@basealt.ru
