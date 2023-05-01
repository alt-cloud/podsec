# Установка и настройка U7S (rootless kuber) по состоянию на 1.05.2023 (podsec-k8s версии >= 0.9.9)

## Установка master-узла

1 Настройте репозиторий обновления
<pre>
apt-repo add 'rpm [p10] http://ftp.altlinux.org/pub/distributions/ALTLinux p10/branch/x86_64 classic'
apt-repo add 'rpm [p10] http://ftp.altlinux.org/pub/distributions/ALTLinux p10/branch/x86_64-i586 classic'
apt-repo add 'rpm [p10] http://ftp.altlinux.org/pub/distributions/ALTLinux p10/branch/noarch classic'
rm -f /etc/apt/sources.list.d/sources.list
apt-get update
</pre>

2 Установите podsec-пакеты:

```
# apt-get install -y podsec-0.9.9-alt1.noarch.rpm      podsec-k8s-rbac-0.9.9-alt1.noarch.rpm podsec-k8s-0.9.9-alt1.noarch.rpm  podsec-inotify-0.9.9-alt1.noarch.rpm
```

3 Запустите команду:

<pre>
# podsec-u7s-kubelet init
</pre>

После:

- генерации сертификатов в каталоге `/etc/kuarnetes/pki`, 
- загрузки образов, -генерации conf-файлов в каталоге `/etc/kubernetes/manifests/`, `/etc/kubernetes/manifests/etcd/`
- запуска сервиса `kubelet` и `Pod`'ов системных `kubernetes-образов`

инициализируется `kubernet-кластер` из одного узла.

По окончании скрипт выводит строки подключения `master`(`Control Plane`) и `worker-узлов`:
<pre>
You can now join any number of control-plane nodes by copying certificate authorities
and service account keys on each node and then running the following as root:

kubeadm join xxx.xxx.xxx.xxx:6443 --token ... \
        --discovery-token-ca-cert-hash sha256:... \
        --control-plane 

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.122.212:6443 --token ... \
        --discovery-token-ca-cert-hash sha256:...
</pre>

5 После завершения скрипта проверьте работу `usernetes` (`rootless kuber`)

<pre>
# kubectl get nodes -o wide
NAME       STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE           KERNEL-VERSION         CONTAINER-RUNTIME
&lt;host>     Ready    control-plane   16m   v1.26.3   10.96.0.1     <none>        ALT SP Server 11100-01   5.15.105-un-def-alt1   cri-o://1.26.2
</pre>

Проверьте работу `usernetes` (`rootless kuber`)

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

Состояние всех Pod'ов должны быть в `1/1`.

Проверьте состояние дерева процессов:
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
Процесс `kubelet`  запускается как сервис в `user namespace` процесса `rootlesskit`.

Все остальные процессы `kube-controller`, `kube-apiserver`, `kube-scheduler`, `kube-proxy`, `etcd`, `coredns` запускаются как контейнеры от соответствующих образов `registry.local/k8s-p10/kube-controller-manager:v1.26.3`, `registry.local/k8s-p10/kube-apiserver:v1.26.3`, `registry.local/k8s-p10/kube-scheduler:v1.26.3`, `registry.local/k8s-p10/kube-proxy:v1.26.3`, `registry.local/k8s-p10/etcd:3.5.6-0`,  `registry.local/k8s-p10/coredns:v1.9.3`.

6. По умолчанию на master-узле пользовательские `Pod`ы не запускаются. Чтобы снять это ограничение наберите команду:
```
# kubectl taint nodes &lt;host> node-role.kubernetes.io/control-plane:NoSchedule-
node/<host> untainted
```

6. Проверьте загрузку deployment nginx:

```
# kubectl apply -f https://k8s.io/examples/application/deployment.yaml
```

После загрузки образов `nginx` проверьте состояние `deployment` и `Pod`ов:
```
# kubectl get deployments.apps,pods
NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-deployment   2/2     2            2           5m34s

NAME                                    READY   STATUS    RESTARTS   AGE
pod/nginx-deployment-85996f8dbd-2dw9h   1/1     Running   0          5m34s
pod/nginx-deployment-85996f8dbd-r5dt4   1/1     Running   0          5m34s
```


6 Проверьте загрузку образа `registry.local/alt/alt`:
```
# kubectl run -it --image=registry.local/alt/alt -- bash
If you don't see a command prompt, try pressing enter.
[root@bash /]# pwd
```


8. Пока сервис не стартует после перезагрузки. Для запуска сервиса наберите:
<pre>
systemctl  start u7s
</pre>

## Настройка администратора u7s-admin

Задайте пароль пользователю `u7s-admin`:
```
# passwd u7s-admin
```

Зайдите под пользователем `u7s-admin`.

### Вход в namespace работающих сервисов и контейнеров.

Для захода в `user namespace` перейдите в каталог 
```
$ cd ~/usernetes/boot
```
и наберите команду
```
$ ./nsenter.sh
[INFO] Entering RootlessKit namespaces: OK
[root@<host> boot]# 
```

В `user namespace`:

- Вы работаете от имени `root` (находясь с точки зрения системы в пользователе `u7s-admin`)
- в файловой системе присутствуют каталоги и файлы используемые сервисом `kubelet` и работающих `Pod`ов и возможно отсутствующие в основной файловой системе;
- присутствуют сетевые интерфейсы используемые в `rootless kubernetes`, но отсутсвующие в основной системе (см. команду `ip a`, `ip r`);
- присутствуют правила фильтрации и переадресации (`iptables`, `iptables -t nat`) использующиеся в `rootless kubernetes`, но отсутствующие в основной системе.

