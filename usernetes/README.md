# Установка и настройка U7S (rootless kuber) по состоянию на 16.05.2023 (podsec-k8s версии >= 0.9.32)

На 16.05.2023 функционал `U7S` (`rootless kuber`)  в большей части совпадает с функционалом `rootfull kuber`.

Основные отличия:

- для разворачивания `rootless kubernetes` используется набор образов `registry.altlinux.org/k8s-p10`;

- команда разворачивания кластера `kubeadm` пакета `podsec-k8s` (алиас shell-скрипта `podsec-k8s/bin/podsec-u7s-kubeadm`) поддерживает основные подкоманды и флаги для разворачивания кластера, но не поддерживает все. Для вызова "родной" команды `kubeadm` пакета `kubernetes-kubeadm` необходимо в пользователе `u7s-admin` запустить команду:
  <pre>
  $ nsenter_u7s /usr/bin/kubeadm <подкоманда> <параметры>...
  </pre>

- при использовании сервисов типа `NodePort` поднятые в рамках кластера порты в диапазоне `30000-32767` остаются в `namespace` пользователя `u7s-admin`. Для их проброса наружу необходимо в пользователе `u7s-admin` запустить команду:

  <pre>
  $ nsenter_u7s rootlessctl.sh add-ports 0.0.0.0:<port>:<port>/tcp
  </pre>

Сервисы типа `NodePort` из за их небольшого диапазона и "нестабильности" портов при переносе решения в другой кластер довольно редко используются. Рекомендуется вместо них использовать сервисы типа `ClusterIP` c доступом к ним через `Ingress`-контроллеры.

- Для настройки сети используется сетевой плагин `flannel`. Настройка других типов сетевых плагинов планируется.

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
# apt-get install -y podsec-0.9.32-alt1.noarch.rpm podsec-k8s-rbac-0.9.32-alt1.noarch.rpm podsec-k8s-0.9.32-alt1.noarch.rpm  podsec-inotify-0.9.32-alt1.noarch.rpm
```

3. Измените переменную PATH:

<pre> 
export PATH=/usr/libexec/podsec/u7s/bin/:$PATH
</pre>

4. Запустите команду:

<pre>
# kubeadm init
</pre>

> По умолчанию уровень отладки устанавливается в `0`. Если необходимо увеличить уровень отладки укажите перед подкомандой `init` флаг `-v n`. Где `n` принимает значения от `0` до `9`-ти.

После:

- генерации сертификатов в каталоге `/etc/kuarnetes/pki`, 
- загрузки образов, -генерации conf-файлов в каталоге `/etc/kubernetes/manifests/`, `/etc/kubernetes/manifests/etcd/`
- запуска сервиса `kubelet` и `Pod`'ов системных `kubernetes-образов`

инициализируется `kubernet-кластер` из одного узла.

По окончании скрипт выводит строки подключения `master`(`Control Plane`) и `worker-узлов`:
<pre>
You can now join any number of control-plane nodes by copying certificate authorities
and service account keys on each node and then running the following as root:

kubeadm join xxx.xxx.xxx.xxx:6443 --token ... --discovery-token-ca-cert-hash sha256:.. --control-plane 

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join xxx.xxx.xxx.xxx:6443 --token ... --discovery-token-ca-cert-hash sha256:...
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
# kubectl taint nodes <host> node-role.kubernetes.io/control-plane:NoSchedule-
node/<host> untainted
```

7. Проверьте загрузку deployment nginx:

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


8. Проверьте загрузку образа `registry.local/alt/alt`:
```
# kubectl run -it --image=registry.local/alt/alt -- bash
If you don't see a command prompt, try pressing enter.
[root@bash /]# pwd
```


## Подключение worker-узла

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
# apt-get install -y podsec-0.9.32-alt1.noarch.rpm      podsec-k8s-rbac-0.9.32-alt1.noarch.rpm podsec-k8s-0.9.32-alt1.noarch.rpm  podsec-inotify-0.9.32-alt1.noarch.rpm
```

3. Измените переменную PATH:

<pre> 
export PATH=/usr/libexec/podsec/u7s/bin/:$PATH
</pre>


4. Скопируйте команду подключния `worker-узла`, полученную на этапе установки начального `master-узла`.  Запустите ее:

```
kubeadm join xxx.xxx.xxx.xxx:6443 --token ... --discovery-token-ca-cert-hash sha256:...
```

> По умолчанию уровень отладки устанавливается в `0`. Если необходимо увеличить уровень отладки укажите перед подкомандой `join` флаг `-v n`. Где `n` принимает значения от `0` до `9`-ти.

По окончании скрипт выводит текст:
<pre>
This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.
</pre>

5. Проверьте состояние дерева процессов:
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
Процесс `kubelet`  запускается как сервис в `user namespace` процесса `rootlesskit`.

Все остальные процессы `kube-proxy`, `kube-flannel` запускаются как контейнеры от соответствующих образов `registry.local/k8s-p10/kube-proxy:v1.26.3`, `registry.local/k8s-p10/flannel:v0.19.2`.

6. Зайдите на `master-узел` и проверьте подключение `worker-узла`:
```
# kubectl get nodes -o wide
NAME       STATUS   ROLES           AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                 KERNEL-VERSION         CONTAINER-RUNTIME
host-212   Ready    control-plane   7h54m   v1.26.3   10.96.0.1     <none>        ALT SP Server 11100-01   5.15.105-un-def-alt1   cri-o://1.26.2
host-226   Ready    <none>          8m30s   v1.26.3   10.96.0.1     <none>        ALT SP Server 11100-01   5.15.105-un-def-alt1   cri-o://1.26.2
```

7. На `master-узле` под пользоваталем `root` выполните команду:

```
# kubectl apply -f /etc/kubernetes/manifests/kube-flannel.yml
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

8. На `master-узле` выполните команду:
```
# kubectl get daemonsets.apps -A
NAMESPACE      NAME              DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
kube-flannel   kube-flannel-ds   2         2         2       2            1           <none>                   102s
kube-system    kube-proxy        2         2         2       2            2           kubernetes.io/os=linux   8h
```
Число `READY` каждого `daemonset` должно быть равно числу `DESIRED` и должно быть равно числу узлов кластера.


## Подключение control-plane (master)-узла

При подключении дополнительного `control-plane`(`master`)-узла необходимо 

- установить и настроить на один из улов в кластере или вне его `haproxy` для балансировки запросов;
- переустановить начальный `master-узел` для работы с `haproxy`
- подключать дополнительные `control-plane`(`master`)-узлы с указанием их в балансировщике запросов `haproxy`;
- подключать дополнительные `worker`-узлы

### Установка и настройка балансировщика запросов haproxy

Полная настройка отказоустойчивого кластера `haproxy` из 3-х узлов описана в документе  
[ALT Container OS подветка K8S. Создание HA кластера](https://www.altlinux.org/ALT_Container_OS_%D0%BF%D0%BE%D0%B4%D0%B2%D0%B5%D1%82%D0%BA%D0%B0_K8S._%D0%A1%D0%BE%D0%B7%D0%B4%D0%B0%D0%BD%D0%B8%D0%B5_HA_%D0%BA%D0%BB%D0%B0%D1%81%D1%82%D0%B5%D1%80%D0%B0).

Здесь же мы рассмотрим создание и настройка с один `haproxy` с балансировкой запросов на `master`-узлы.

Установите пакет `haproxy`:
```
# apt-get install haproxy
```

Отредактируйте конфигурационный файл `/etc/haproxy/haproxy.cfg`:

- добавьте в него описание `frontend`'a `main`, принимающего запросы по порту `8443`:
<pre> 
 frontend main
    bind *:8443
    mode tcp
    option tcplog
    default_backend apiserver
</pre>

- добавьте описание `backend`'а `apiserver`:
<pre>
backend apiserver
    option httpchk GET /healthz
    http-check expect status 200
    mode tcp
    option ssl-hello-chk
    balance     roundrobin
        server master01 &lt;IP_или_DNS_начального_мастер_узла>:6443 check
</pre>

- запустите `haproxy`:
```
# systemctl enable haproxy
# systemctl start haproxy
```

### Установка начального master-узла для работы с haproxy

Настройте репозиторий обновления
<pre>
apt-repo add 'rpm [p10] http://ftp.altlinux.org/pub/distributions/ALTLinux p10/branch/x86_64 classic'
apt-repo add 'rpm [p10] http://ftp.altlinux.org/pub/distributions/ALTLinux p10/branch/x86_64-i586 classic'
apt-repo add 'rpm [p10] http://ftp.altlinux.org/pub/distributions/ALTLinux p10/branch/noarch classic'
rm -f /etc/apt/sources.list.d/sources.list
apt-get update
</pre>

Установите podsec-пакеты версии *0.9.32-alt1* и выше:

```
# apt-get install -y podsec-0.9.32-alt1.noarch.rpm  podsec-k8s-rbac-0.9.32-alt1.noarch.rpm podsec-k8s-0.9.32-alt1.noarch.rpm  podsec-inotify-0.9.32-alt1.noarch.rpm
```

Измените переменную `PATH`:

<pre> 
export PATH=/usr/libexec/podsec/u7s/bin/:$PATH
</pre>

При установке начального master-узла необходимо параметром `control-plane-endpoint` указать URL  балансировщика `haproxy`:
```
# kubeadm init --control-plane-endpoint <IP_адрес_haproxy>:8443
```

В результате инициализации `kubeadm` выведет команды подключения дополнительных `control-plane` и `worker` узлов:
<pre> 
...
You can now join any number of the control-plane node running the following command on each as root:

kubeadm join <IP_адрес_haproxy>:8443 --token ... \
        --discovery-token-ca-cert-hash sha256:... \
        --control-plane --certificate-key ...

Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use
"kubeadm init phase upload-certs --upload-certs" to reload certs afterward.

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join <IP_адрес_haproxy>:8443 --token ... \
        --discovery-token-ca-cert-hash sha256:...
...
</pre>

Обратите внимание - в командах присоединения узлов указывается не URL созданного начального master-узла (`<IP_или_DNS_начального_мастер_узла>:6443`),
а URL `haproxy`.

В сформированных файлах конфигурации `/etc/kubernetes/admin.conf`, `~/.kube/config` также указывается URL `haproxy`:  
<pre>
apiVersion: v1
clusters:
- cluster:
...
    server: https://&lt;IP_адрес_haproxy>:8443
</pre>

То есть вся работа с кластеров в дальнейшем идет через балансировщик запросов `haproxy`.

### Подключение дополнительных ControlPlane(master)-узлов с указанием их в балансировщике запросов haproxy

Настройте репозиторий обновления
<pre>
apt-repo add 'rpm [p10] http://ftp.altlinux.org/pub/distributions/ALTLinux p10/branch/x86_64 classic'
apt-repo add 'rpm [p10] http://ftp.altlinux.org/pub/distributions/ALTLinux p10/branch/x86_64-i586 classic'
apt-repo add 'rpm [p10] http://ftp.altlinux.org/pub/distributions/ALTLinux p10/branch/noarch classic'
rm -f /etc/apt/sources.list.d/sources.list
apt-get update
</pre>

Установите podsec-пакеты версии *0.9.32-alt1* и выше:

```
# apt-get install -y podsec-0.9.32-alt1.noarch.rpm  podsec-k8s-rbac-0.9.32-alt1.noarch.rpm podsec-k8s-0.9.32-alt1.noarch.rpm  podsec-inotify-0.9.32-alt1.noarch.rpm
```

Измените переменную `PATH`:

<pre> 
export PATH=/usr/libexec/podsec/u7s/bin/:$PATH
</pre>

Скопируйте строку подключения  `control-plane` узла и вызовите ее:
```
# kubeadm join <IP_адрес_haproxy>:8443 --token ... \
        --discovery-token-ca-cert-hash sha256:... \
        --control-plane --certificate-key ...
```

В результате работы команда kubeadm выведет строки:
<pre> 
 This node has joined the cluster and a new control plane instance was created:

* Certificate signing request was sent to apiserver and approval was received.
* The Kubelet was informed of the new secure connection details.
* Control plane label and taint were applied to the new node.
* The Kubernetes control plane instances scaled up.
* A new etcd member was added to the local/stacked etcd cluster.
...
Run 'kubectl get nodes' to see this node join the cluster.
</pre>

Наберите на вновь созданном (или начальном)`control-plane` узле команду:  
```
# kubectl  get nodes
NAME       STATUS   ROLES           AGE     VERSION
<host1>   Ready    control-plane   4m31s   v1.26.3
<host2>   Ready    control-plane   26s     v1.26.3

```
Обратите внимание, что роль (ROLES) обоих узлов - `control-plane`.

Наберите команду:
<pre>  
# kubectl get all -A
NAMESPACE      NAME                                   READY   STATUS    RESTARTS       AGE    IP             NODE       NOMINATED NODE   READINESS GATES
kube-flannel   pod/kube-flannel-ds-2mhqg              1/1     Running   0              153m   10.96.0.1      <host1>   <none>           <none>
kube-flannel   pod/kube-flannel-ds-95ht2              1/1     Running   0              153m   10.96.122.68   <host2>    <none>           <none>
...
kube-system    pod/etcd-<host1>                       1/1     Running   0              174m   10.96.0.1      <host1>   <none>           <none>
kube-system    pod/etcd-<host2>                       1/1     Running   0              170m   10.96.122.68   <host2>    <none>           <none>

kube-system    pod/kube-apiserver-<host1>             1/1     Running   0              174m   10.96.0.1      <host1>   <none>           <none>
kube-system    pod/kube-apiserver-<host2>             1/1     Running   0              170m   10.96.122.68   <host2>    <none>           <none>

kube-system    pod/kube-controller-manager-<host1>    1/1     Running   1 (170m ago)   174m   10.96.0.1      <host1>   <none>           <none>
kube-system    pod/kube-controller-manager-<host2>    1/1     Running   0              170m   10.96.122.68   <host2>    <none>           <none>

kube-system    pod/kube-proxy-9nbxz                   1/1     Running   0              174m   10.96.0.1      <host1>   <none>           <none>
kube-system    pod/kube-proxy-bnmd7                   1/1     Running   0              170m   10.96.122.68   <host2>    <none>           <none>

kube-system    pod/kube-scheduler-<host1>             1/1     Running   1 (170m ago)   174m   10.96.0.1      <host1>   <none>           <none>
kube-system    pod/kube-scheduler-<host2>             1/1     Running   0              170m   10.96.122.68   <host2>    <none>           <none>
...

NAMESPACE      NAME                             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE    CONTAINERS     IMAGES                                      SELECTOR
kube-flannel   daemonset.apps/kube-flannel-ds   2         2         2       3            3           <none>                   153m   kube-flannel   registry.local/k8s-p10/flannel:v0.19.2      app=flannel
kube-system    daemonset.apps/kube-proxy        2         2         2       2            2           kubernetes.io/os=linux   174m   kube-proxy     registry.local/k8s-p10/kube-proxy:v1.26.3   k8s-app=kube-proxy
...
</pre>

Убедитесь, что сервисы `pod/etcd`, `kube-apiserver`, `kube-controller-manager`, `kube-scheduler`, `kube-proxy`, `kube-flannel` запустились на обоих control-plane узлах.

Для балансировки запросов по двум серверам добавьте URL подключенного `control-plane` узла в файл конфигурации `/etc/haproxy/haproxy.cfg`:  
<pre> 
backend apiserver
    option httpchk GET /healthz
    http-check expect status 200
    mode tcp
    option ssl-hello-chk
    balance     roundrobin
        server master01 &lt;IP_или_DNS_начального_мастер_узла>:6443 check
        server master02 &lt;IP_или_DNS_подключенного_мастер_узла>:6443 check
</pre>

и перезапустите `haproxy`:
```
# systemctl restart haproxy
```

### Подключение дополнительных worker-узлов

Подключение дополнительных worker-узлов происходит аналогично описанному выше в главе **Подключение worker-узла**.


## Работа под администратором u7s-admin rootless процессов

В случае если Вам необходимо отслеживать состояние процессов, файловой системы, интерфейсов, правил фильтрации и редиректа необходимо на каждом работающем узле задать пароль пользователя `u7s-admin` от имени которого запускаются все `rootless`-процессы `kubernetes`:
```
# passwd u7s-admin
```

После задания пароля зайдите под пользовате `u7s-admin`.

### Вход в namespace работающих сервисов и контейнеров.

Для захода в `user namespace` наберите команду
```
$ nsenter_u7s
[INFO] Entering RootlessKit namespaces: OK
[root@<host> boot]# 
```

В `user namespace`:

- Вы для `user namespace` процессов имеете права `root` (находясь с точки зрения системы в пользователе `u7s-admin`)

- в файловой системе присутствуют каталоги и файлы (`/run/crio/crio.sock`, ...) используемые сервисом `kubelet` и работающих `Pod`ов и частично отсутствующие в основной файловой системе;

- присутствуют сетевые интерфейсы используемые в `rootless kubernetes`, но отсутсвующие в основной системе (см. команду `ip a`, `ip r`);

- присутствуют правила фильтрации и переадресации (`iptables`, `iptables -t nat`) использующиеся в `rootless kubernetes`, но отсутствующие в основной системе;

- Вы можете выполнять привелигированные команды по настройке узла: `ip`, `iptables`, ...


### Тестирование новых версий пакета podsec-k8s

Для тестирования новых версий пакета `podsec-k8s` нет необходимости повторно инициализировать виртуальную машину.

Необходимо:

- в пользователе `u7s-admin` 
  * остановить сервис
  <pre> 
   systemctl --user stop u7s.target
  </pre>
  * на мастер-узле удалить базу `etcd`:
  <pre> 
  $ rm -rf /var/lib/podsec/u7s/etcd/member/
  </pre>

- в пользователе `root`:
  * если текущая версия пакета совпадает с новой удалить пакет  
  <pre> 
  # apt-get remove -y podsec-k8s
  </pre>
  * установить новый пакет;
  * запустите команду `kubeadm init` или `kubeadm join`;


