podsec-k8s-create-master(1) -- initialize master node rootfull-kubernetes
=================================

## SYNOPSIS

`podsec-k8s-create-master username_with_administrative_rights`

## DESCRIPTION

The script:

- Configure /etc/crio/crio.conf to use `registry.local/k8s-c10f1/pause:3.9` as the pause image

- Start service `kubelet`

- Initialize `master node` of the cluster

- Configure `root` to the role of *cluster administrator*

- Configure `specified user` to the role of *cluster administrator*

- Configure audit of API service kubernetes.

After the script finishes running, don't forget to copy the worker node connection string from the cluster initialization stage output
`kubeadm join xx.xx.xx.xx:6443 --token ... --discovery-token-ca-cert-hash sha256:...`
You will need to use this command later to connect the cluster worker nodes.

## EXAMPLES

`podsec-k8s-create-master securityadmin`

## SECURITY CONSIDERATIONS

- To work as a *containerization tool security administrator*, you need to create a user (for example, `securityadmin`) on the master node that belongs to the `podman`, `wheel` groups.

- Since all work with the cluster is performed via the REST interface, then to ensure increased security measures, you should create **ALL users**, including the *containerization tool security administrator* **OUTSIDE the cluster nodes**. To work with the cluster, the `kubectl` command, included in the `kubernetes-client` package, is sufficient.

## SEE ALSO

- [Kubernetes](https://www.altlinux.org/Kubernetes);

- [Configuring API service audit](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/clusterroleBinding.md);

## AUTHOR

Alexey Kostarev, Basalt LLC
kaf@basealt.ru
