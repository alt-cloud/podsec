podsec-u7s-kubeadm(1) -- initialize master or worker node in rootless kubernetes (alt usernetes)
=================================

## SYNOPSIS

`podsec-u7s-kubeadm init| join <ApiServer>:6443 --token ... --discovery-token-ca-cert-hash ...`

## DESCRIPTION

## Installing master node

1. Modify PATH variable:

<pre>
export PATH=/usr/libexec/podsec/u7s/bin/:$PATH
</pre>

2. Run command:

<pre>
# kubeadm init
</pre>

> By default debug level is set to `0`. If you need to increase the debug level, specify the `-v n` flag before the `init` subcommand. Where `n` takes values ​​from `0` to `9`.

After:

- generating certificates in the `/etc/kuarnetes/pki` directory,
- downloading images, - generating conf files in the `/etc/kubernetes/manifests/`, `/etc/kubernetes/manifests/etcd/` directory
- starting the `kubelet` service and `Pod`s of the system `kubernetes images`

a `kubernet cluster` from one node is initialized.

When finished, the script prints the `master` (`Control Plane`) and `worker-nodes` connection strings:

<pre>
You can now join any number of control-plane nodes by copying certificate authorities
and service account keys on each node and then running the following as root:

kubeadm join xxx.xxx.xxx.xxx:6443 --token ... --discovery-token-ca-cert-hash sha256:.. --control-plane

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join xxx.xxx.xxx.xxx:6443 --token ... --discovery-token-ca-cert-hash sha256:...
</pre>

3. After the script completes, check the `usernetes` (`rootless kuber`) operation

<pre>
# kubectl get nodes -o wide
NAME       STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE           KERNEL-VERSION         CONTAINER-RUNTIME
&lt;host>     Ready    control-plane   16m   v1.26.3   10.96.0.1     <none>        ALT SP Server 11100-01   5.15.105-un-def-alt1   cri-o://1.26.2
</pre>

Check if `usernetes` (`rootless kuber`) is working
<pre>
# kubectl get all -A
NAMESPACE     NAME                                   READY   STATUS    RESTARTS   AGE
kube-system   pod/coredns-c7df5cd6c-5pkkm            1/1     Running   0          19m
kube-system   pod/coredns-c7df5cd6c-cm6vf            1/1     Running   0          19m
kube-system   pod/etcd-host-212                      1/1     Running   0          19m
kube-system   pod/kube-apiserver-host-212            1/1     Running   0          19m
kube-system   pod/kube-controller-manager-host-212   1/1     Running   0          19m
kube-system   pod/kube-proxy-lqf9c                   1/1     Running   0          19m
kube-system   pod/kube-scheduler-host-212            1/1     Running   0          19m

NAMESPACE     NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
default       service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP                  19m
kube-system   service/kube-dns     ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   19m

NAMESPACE     NAME                        DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
kube-system   daemonset.apps/kube-proxy   1         1         1       1            1           kubernetes.io/os=linux   19m

NAMESPACE     NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
kube-system   deployment.apps/coredns   2/2     2            2           19m

NAMESPACE     NAME                                DESIRED   CURRENT   READY   AGE
kube-system   replicaset.apps/coredns-c7df5cd6c   2         2         2       19m
</pre>

All Pods should be in `1/1` state.

Check the process tree state:
<pre>
# pstree
...
├─systemd─┬─(sd-pam)
│         ├─dbus-daemon
│         ├─nsenter.sh───nsenter───_kubelet.sh───kubelet───11*[{kubelet}]
│         └─rootlesskit.sh───rootlesskit─┬─exe─┬─conmon───kube-controller───7*[{kube-controller}]
│                                        │     ├─conmon───kube-apiserver───8*[{kube-apiserver}]
│                                        │     ├─conmon───kube-scheduler───7*[{kube-scheduler}]
│                                        │     ├─conmon───etcd───8*[{etcd}]
│                                        │     ├─conmon───kube-proxy───4*[{kube-proxy}]
│                                        │     ├─2*[conmon───coredns───8*[{coredns}]]
│                                        │     ├─rootlesskit.sh───crio───10*[{crio}]
│                                        │     └─7*[{exe}]
│                                        ├─slirp4netns
│                                        └─8*[{rootlesskit}]
...
</pre>
The `kubelet` process runs as a service in the `user namespace` of the `rootlesskit` process.

All other processes `kube-controller`, `kube-apiserver`, `kube-scheduler`, `kube-proxy`, `etcd`, `coredns` are launched as containers from the corresponding images `registry.local/k8s-c10f1/kube-controller-manager:v1.26.3`, `registry.local/k8s-c10f1/kube-apiserver:v1.26.3`, `registry.local/k8s-c10f1/kube-scheduler:v1.26.3`, `registry.local/k8s-c10f1/kube-proxy:v1.26.3`, `registry.local/k8s-c10f1/etcd:3.5.6-0`, `registry.local/k8s-c10f1/coredns:v1.9.3`.

4. By default, user `Pods` are not launched on the master node. To remove this restriction, enter the command:

```
# kubectl taint nodes <host> node-role.kubernetes.io/control-plane:NoSchedule-
node/<host> untainted
```

5. Check the loading of the nginx deployment:
```
# kubectl apply -f https://k8s.io/examples/application/deployment.yaml
```

After downloading the `nginx` images, check the status of the `deployment` and `Pods`:
```
# kubectl get deployments.apps.pods
NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-deployment   2/2     2            2           5m34s

NAME                                    READY   STATUS    RESTARTS   AGE
pod/nginx-deployment-85996f8dbd-2dw9h   1/1     Running   0          5m34s
pod/nginx-deployment-85996f8dbd-r5dt4   1/1     Running   0          5m34s
```

6. Check loading of the `registry.local/alt/alt` image:
```
# kubectl run -it --image=registry.local/alt/alt -- bash
If you don't see a command prompt, try pressing enter.
[root@bash /]# pwd
```


## Connecting a worker node

1. Change the PATH variable:

<pre>
export PATH=/usr/libexec/podsec/u7s/bin/:$PATH
</pre>


2. Copy the `worker node` connection command obtained during the initial `master node` setup step. Run it:

```
kubeadm join xxx.xxx.xxx.xxx:6443 --token ... --discovery-token-ca-cert-hash sha256:...
```

> By default, the debug level is set to `0`. If you need to increase the debug level, specify the `-v n` flag before the `join` subcommand. Where `n` takes values ​​from `0` to `9`.

When finished, the script outputs the text:
<pre>
This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.
</pre>


3. Check the state of the process tree:
<pre>
# pstree
...
├─systemd─┬─(sd-pam)
│         ├─dbus-daemon
│         ├─nsenter.sh───nsenter───_kubelet.sh───kubelet───10*[{kubelet}]
│         └─rootlesskit.sh───rootlesskit─┬─exe─┬─conmon───kube-proxy───4*[{kube-proxy}]
│                                        │     ├─rootlesskit.sh───crio───9*[{crio}]
│                                        │     └─6*[{exe}]
│                                        ├─slirp4netns
│                                        └─8*[{rootlesskit}]
...
</pre>
The `kubelet` process is started as a service in the `user namespace` of the `rootlesskit` process.

All other `kube-proxy`, `kube-flannel` processes are started as containers from the corresponding images `registry.local/k8s-c10f1/kube-proxy:v1.26.3`, `registry.local/k8s-c10f1/flannel:v0.19.2`.

4 Log in to the `master-node` and check the connection of the `worker-node`:
```
# kubectl get nodes -o wide
NAME       STATUS   ROLES           AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                 KERNEL-VERSION         CONTAINER-RUNTIME
host-212   Ready    control-plane   7h54m   v1.26.3   10.96.0.1     <none>        ALT SP Server 11100-01   5.15.105-un-def-alt1   cri-o://1.26.2
host-226   Ready    <none>          8m30s   v1.26.3   10.96.0.1     <none>        ALT SP Server 11100-01   5.15.105-un-def-alt1   cri-o://1.26.2
```

5. On the `master node`, run the command as the `root` user:
```
# machinectl shell u7s-admin@ ~u7s-admin/usernetes/boot/nsenter.sh \
    kubectl apply -f ~u7s-admin/usernetes/manifests/kube-flannel.yml
Connected to the local host. Press ^] three times within 1s to exit session.
[INFO] Entering RootlessKit namespaces: OK
namespace/kube-flannel created
clusterrole.rbac.authorization.k8s.io/flannel created
clusterrolebinding.rbac.authorization.k8s.io/flannel created
serviceaccount/flannel created
configmap/kube-flannel-cfg created
daemonset.apps/kube-flannel-ds created
Connection to the local host terminated.
```

6. On the `master node`, run the command:
```
# kubectl get daemonsets.apps -A
NAMESPACE      NAME              DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
kube-flannel   kube-flannel-ds   2         2         2       2            1           <none>                   102s
kube-system    kube-proxy        2         2         2       2            2           kubernetes.io/os=linux   8h
```
Число `READY` каждого `daemonset` должно быть равно числу `DESIRED` и должно быть равно числу узлов кластера.


## EXAMPLES

`podsec-u7s-kubeadm init`
`podsec-u7s-kubeadm join 102.168.122.32:6443 --token ... --discovery-token-ca-cert-hash ...`

## SECURITY CONSIDERATIONS


- Since all work with the cluster is performed via the REST interface, then to ensure increased security measures, **ALL users** should be created, including the *containerization tool security administrator* **OUTSIDE the cluster nodes**. To work with the cluster, the `kubectl` command, included in the `kubernetes-client` package, is sufficient.

## SEE ALSO

- [Kubernetes](https://www.altlinux.org/Kubernetes);

- [Usernetes: Kubernetes without the root privileges](https://github.com/rootless-containers/usernetes);

- [Настройка аудита API-сервиса](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/clusterroleBinding.md);

## AUTHOR

Kostarev Alexey, Basalt LLC
kaf@basealt.ru
