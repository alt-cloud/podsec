# Установка и настройка U7S (rootless kuber) по состоянию на 16.05.2023 (podsec-k8s версии >= 0.9.32)

На 16.05.2023 функционал `U7S` (`rootless kuber`)  в большей части совпадает с функционалом `rootfull kuber`.

Основные отличия:

- для разворачивания `rootless kubernetes` используется набор образов `registry.altlinux.org/k8s-c10f1`;

- команда разворачивания кластера `kubeadm` пакета `podsec-k8s` (алиас shell-скрипта `podsec-k8s/bin/podsec-u7s-kubeadm`) поддерживает основные подкоманды и флаги для разворачивания кластера, но не поддерживает все. Для вызова "родной" команды `kubeadm` пакета `kubernetes-kubeadm` необходимо в пользователе `u7s-admin` запустить команду:
  <pre>
  $ nsenter_u7s /usr/bin/kubeadm <подкоманда> <параметры>...
  </pre>

- при использовании сервисов типа `NodePort` поднятые в рамках кластера порты в диапазоне `30000-32767` остаются в `namespace` пользователя `u7s-admin`. Для их проброса наружу необходимо в пользователе `u7s-admin` запустить команду:

  <pre>
  $ nsenter_u7s rootlessctl.sh add-ports 0.0.0.0:&lt;port>:&lt;port>/tcp
  </pre>

Сервисы типа `NodePort` из за их небольшого диапазона и "нестабильности" портов при переносе решения в другой кластер довольно редко используются. Рекомендуется вместо них использовать сервисы типа `ClusterIP` c доступом к ним через `Ingress`-контроллеры.

- Для настройки сети используется сетевой плагин `flannel`. Настройка других типов сетевых плагинов планируется.

## Установка master-узла

### Настройка репозиторий обновления

<pre>
apt-repo add 'rpm [p10] http://ftp.altlinux.org/pub/distributions/ALTLinux p10/branch/x86_64 classic'
apt-repo add 'rpm [p10] http://ftp.altlinux.org/pub/distributions/ALTLinux p10/branch/x86_64-i586 classic'
apt-repo add 'rpm [p10] http://ftp.altlinux.org/pub/distributions/ALTLinux p10/branch/noarch classic'
rm -f /etc/apt/sources.list.d/sources.list
apt-get update
</pre>

### Установка podsec-пакетов:

```
# apt-get install -y podsec-0.9.38-alt1.noarch.rpm podsec-k8s-rbac-0.9.38-alt1.noarch.rpm podsec-k8s-0.9.38-alt1.noarch.rpm  podsec-inotify-0.9.38-alt1.noarch.rpm
```

### Выделение IP-адресов

Выделите для `регистратора` и `WEB-сервера подписей` **отдельный IP-адрес**. Это может быть доступный из локальной сети адрес другого интерфейса или дополнительный статический адрес на интерфейсе локальной сети.
Основной адрес, используемый для доступа к API-интерфейсу kube-apiserver мастер узла и адрес `регистратора` и `WEB-сервера подписей` должны быть статическими и не изменяться после перезагрузки узла.
Например структура файлов каталога `/etc/net/ifaces/enp1s0` описания интерфейса `ensp1s0` с адресом `192.168.122.70` для `регистратора` и `WEB-сервера подписей` и адресом `192.168.122.80` для `API-интерфейса` `kube-apiserver`:

- `options`:
<pre>
BOOTPROTO=static
TYPE=eth
CONFIG_WIRELESS=no
SYSTEMD_BOOTPROTO=static
CONFIG_IPV4=yes
DISABLED=no
NM_CONTROLLED=no
SYSTEMD_CONTROLLED=no
</pre>

- `ipv4address`:
<pre> 
192.168.122.70/24
192.168.122.80/24
</pre>

- `ipv4route`:
<pre>  
default via 192.168.122.1
</pre>

- `resolv.conf`:
<pre>
nameserver 192.168.122.1
</pre>

Интерфейс для данных параметров выглядит следующим образом:
<pre> 
# ip a show dev enp1s0
2: enp1s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:db:e1:57 brd ff:ff:ff:ff:ff:ff
    inet 192.168.122.70/24 brd 192.168.122.255 scope global enp1s0
       valid_lft forever preferred_lft forever
    inet 192.168.122.80/24 brd 192.168.122.255 scope global secondary enp1s0
       valid_lft forever preferred_lft forever
    ...
</pre>

### Настройка политики контейнеризации

Вызовите команду:
<pre>
# podsec-create-policy 192.168.122.70 # ip-aдрес_регистратора и WEB-сервера подписей
Добавление привязки доменов registry.local sigstore.local к IP-адресу 192.168.122.70
Создание группы podman
Инициализация каталога /var/sigstore/ и подкаталогов хранения открытых ключей и подписей образов
Создание каталога и подкаталогов  /var/sigstore/
Создание группы podman_dev
Создание с сохранением предыдущих файла политик /etc/containers/policy.json
Создание с сохранением предыдущих файл /etc/containers/registries.d/default.yaml описания доступа к открытым ключам подписантов
Добавление insecure-доступа к регистратору registry.local в файле /etc/containers/registries.conf
Настройка использования образа registry.local/k8s-c10f1/pause:3.9 при запуска pod'ов в podman (podman pod init)
</pre>

После выполнения команды:

- файл `/etc/host` должен содержать строку:
<pre> 
...
192.168.122.70 registry.local sigstore.local
</pre>

- файл `/etc/containers/policy.json`, являющийся `symlink'ом` к файлу `/etc/containers/policy_YYYY-MM-DD_HH:mm:SS`  
 должен иметь содержимое (запрет доступа по всем ресурсам):
<pre> 
{
  "default": [
    {
      "type": "reject"
    }
  ],
  "transports": {
    "docker": {}
  }
} 
</pre>

- файл `/etc/containers/registries.d/default.yaml`, являющийся `symlink'ом` к файлу `/etc/containers/registries.d/default_YYYY-MM-DD_HH:mm:SS` должен иметь содержимое (ю URLs доступа к серверу подписей):
<pre> 
default-docker:
  lookaside: http://sigstore.local:81/sigstore/
  sigstore: http://sigstore.local:81/sigstore/ 
</pre>

### Создание сервисов регистратора и WEB-сервера подписей

Поднимите сервисы `регистратора` и `WEB-сервера подписей` командой:
<pre>
# podsec-create-services
Synchronizing state of nginx.service with SysV service script with /lib/systemd/systemd-sysv-install.
Executing: /lib/systemd/systemd-sysv-install enable nginx
Created symlink /etc/systemd/system/multi-user.target.wants/nginx.service → /lib/systemd/system/nginx.service.
registry
Created symlink /etc/systemd/system/multi-user.target.wants/docker-registry.service → /lib/systemd/system/docker-registry.service.
</pre> 

Проверьте функционирование сервисов:  
<pre>
# netstat -nlpt
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address               Foreign Address             State       PID/Program name 
...  
tcp        0      0 0.0.0.0:81                  0.0.0.0:*                   LISTEN      14996/nginx -g daem 
...
tcp        0      0 :::80                       :::*                        LISTEN      15044/docker-regist 
...
</pre>

### Создание пользователя разработчика образов контейнеров

Cоздайте пользователя *разработчик образов контейнеров*:
<pre>
# podsec-create-imagemakeruser imagemaker
</pre>
Шаги создания пользователя подробно описаны в []().

Файл `/etc/containers/policy.json`, должен изменить `symlink` на другой файл `/etc/containers/policy_YYYY-MM-DD_HH:mm:SS` с содержимым (разрешение доступа к регистратору `registry.local` с открытым ключом пользователя `imagemaker`):
<pre> 
{
  "default": [
    {
      "type": "reject"
    }
  ],
  "transports": {
    "docker": {
      "registry.local": [
        {
          "type": "signedBy",
          "keyType": "GPGKeys",
          "keyPath": "/var/sigstore/keys/imagemaker.pgp"
        }
      ]
    }
  }
} 
</pre>


Должен появится каталог `/var/sigstore/` со следующей структурой:
<pre>
├── index.html
├── keys
│   ├── imagemaker.pgp
│   └── policy.json
└── sigstore
</pre>

Проверьте доступ к этому каталогу через `http`:
<pre>
# curl -s  http://sigstore.local:81/keys/ | jq
[
  {
    "name": "imagemaker.pgp",
    "type": "file",
    "mtime": "Tue, 23 May 2023 05:43:59 GMT",
    "size": 2436
  },
  {
    "name": "policy.json",
    "type": "file",
    "mtime": "Tue, 23 May 2023 05:43:25 GMT",
    "size": 276
  }
]
</pre>


### Создание пользователя информационной системы

Создайте пользователя информационной системы:
<pre> 
# podsec-create-podmanusers poduser
</pre>

### Загрузка kubernetes-образов:

Загрузите kubernetes-образы от пользователя `imagemaker`.
<pre> 
# podsec-load-sign-oci amd64_c10f1.tar.xz amd64 <E-mail_подписанта>
</pre>

Во время выполнения скрипта будет запрошен пароль для подписи.

**Внимание**: Данную команду нельзя запускать путем получения прав пользователя через команду `su - imagemaker`, так как устанавливаются не все переменные среды. Сделайте полный заход под пользователем, например по протоколу `ssh`:
```
# ssh imagemaker@localhost
```

После выполнения скрипта проверьте наличие образов в регистраторе:
<pre> 
# curl -s registry.local/v2/_catalog | jq
{
  "repositories": [
    "k8s-c10f1/cert-manager-cainjector",
    "k8s-c10f1/cert-manager-controller",
    "k8s-c10f1/cert-manager-webhook",
    "k8s-c10f1/coredns",
    "k8s-c10f1/etcd",
    "k8s-c10f1/flannel",
    "k8s-c10f1/flannel-cni-plugin",
    "k8s-c10f1/kube-apiserver",
    "k8s-c10f1/kube-controller-manager",
    "k8s-c10f1/kube-proxy",
    "k8s-c10f1/kube-scheduler",
    "k8s-c10f1/pause"
  ]
}
</pre>

И наличие подписей в каталоге `/var/sigstore/sigstore/k8s-c10f1`:
<pre>
└── k8s-c10f1
    ├── cert-manager-cainjector@sha256=36a19269312740daa04ea77e4edb87983230d6c4e6e5dd95b9c3640e5fa300b5
    │   └── signature-1
    ├── cert-manager-controller@sha256=0d6eed2c732d605488e51c3d74aa61d29eb75b2cfadd0276488791261368b911
    │   └── signature-1
    ├── cert-manager-webhook@sha256=7f0ca1ca7724c31b95efc0cfa21f91768e8e057e9a42a9c1e24d18960c9fe88c
    │   └── signature-1
    ├── coredns@sha256=5256bbacc84b80295e64b51d03577dc0494f7db7944ae95b7a63fd6cb0c7737a
    │   └── signatuдкаталогов re-1
    ├── etcd@sha256=da030977338e36b5a1cadb6380a1f87c2cbda4da4950bd915328c3aed5264896
    │   └── signature-1
    ├── flannel-cni-plugin@sha256=8fdc6ac8dbbc9916814a950471e1bf9da9e3928dca342216f931d96b6e9017fe
    │   └── signature-1
    ├── flannel@sha256=7994c6c2a5e0e6d206b84a516b0a4215ba9de3b898cab9972f0015f8fd0c0f69
    │   └── signature-1
    ├── kube-apiserver@sha256=035d353805cc994b12a030c9495adddb66fc91e4325b879e4578c7603b1bb982
    │   └── signature-1
    ├── kube-controller-manager@sha256=50217c9d11a0d41b069efa231958fada60de3666d8c682df297ee371f7e559c0
    │   └── signature-1
    ├── kube-proxy@sha256=d6e80ea2485beb059cb1c565fc92f91561c3e28a335c022da4d548f429b811da
    │   └── signature-1
    ├── kube-scheduler@sha256=ad17d07c44aff8d0e8ca234f051556761bdeb82d4f62ff892a4f7aa7d9f027d4
    │   └── signature-1
    └── pause@sha256=f14315ad18ed3dc1672572c3af9f6b28427cf036a43cc00ebac885e919b59548
        └── signature-1
</pre>
Число подкаталогов должно совпадать с числом образов в регистраторе и каждый подкаталог должен иметь файл `signature-1`.


### Установка тропы PATH поиска исполняемых команд

Измените переменную PATH:
<pre>
export PATH=/usr/libexec/podsec/u7s/bin/:$PATH
</pre>

### Инициализация мастер-узла

При запуске в параметре `--apiserver-advertise-address` укажите IP-адрес API-интерфейса `kube-apiserver`.
**Этот адрес должен отличаться от IP-адреса регистратора и WEB-сервера подписей.**

Запустите команду:
<pre>
# kubeadm -v 9 init  --apiserver-advertise-address 192.168.122.80
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

### Проверка работы узла

После завершения скрипта  в течении минуты настраиваются сервисы мастер-узла кластера.
По ее истечении проверьте работу `usernetes` (`rootless kuber`)
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

Все остальные процессы `kube-controller`, `kube-apiserver`, `kube-scheduler`, `kube-proxy`, `etcd`, `coredns` запускаются как контейнеры от соответствующих образов `registry.local/k8s-c10f1/kube-controller-manager:v1.26.3`, `registry.local/k8s-c10f1/kube-apiserver:v1.26.3`, `registry.local/k8s-c10f1/kube-scheduler:v1.26.3`, `registry.local/k8s-c10f1/kube-proxy:v1.26.3`, `registry.local/k8s-c10f1/etcd:3.5.6-0`,  `registry.local/k8s-c10f1/coredns:v1.9.3`.


### Обеспечение запуска обычных POD'ов на мастер-узле

По умолчанию на master-узле пользовательские `Pod`ы не запускаются. Чтобы снять это ограничение наберите команду:
```
# kubectl taint nodes <host> node-role.kubernetes.io/control-plane:NoSchedule-
node/<host> untainted
```

<!--
### Проверка загрузки POD'ов 

Проверьте загрузку deployment nginx:

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

### 
14. Проверьте загрузку образа `registry.local/alt/alt`:
```
# kubectl run -it --image=registry.local/alt/alt -- bash
If you don't see a command prompt, try pressing enter.
[root@bash /]# pwd
```
-->

## Подключение worker-узла

### Настройка репозиторий обновления

Настройте репозиторий обновления
<pre>
apt-repo add 'rpm [p10] http://ftp.altlinux.org/pub/distributions/ALTLinux p10/branch/x86_64 classic'
apt-repo add 'rpm [p10] http://ftp.altlinux.org/pub/distributions/ALTLinux p10/branch/x86_64-i586 classic'
apt-repo add 'rpm [p10] http://ftp.altlinux.org/pub/distributions/ALTLinux p10/branch/noarch classic'
rm -f /etc/apt/sources.list.d/sources.list
apt-get update
</pre>

### Установка podsec-пакетов:

Установите podsec-пакеты:

```
# apt-get install -y podsec-0.9.38-alt1.noarch.rpm  podsec-k8s-rbac-0.9.38-alt1.noarch.rpm podsec-k8s-0.9.38-alt1.noarch.rpm  podsec-inotify-0.9.38-alt1.noarch.rpm
```


### Настройка политики контейнеризации

Вызовите команду:
<pre>
# podsec-create-policy 192.168.122.70 # ip-aдрес_регистратора и WEB-сервера подписей
Добавление привязки доменов registry.local sigstore.local к IP-адресу 192.168.122.70
Создание группы podman
Инициализация каталога /var/sigstore/ и подкаталогов хранения открытых ключей и подписей образов
Создание каталога и подкаталогов  /var/sigstore/
Создание с сохранением предыдущих файла политик /etc/containers/policy.json
Создание с сохранением предыдущих файл /etc/containers/registries.d/default.yaml описания доступа к открытым ключам подписантов
Добавление insecure-доступа к регистратору registry.local в файле /etc/containers/registries.conf
Настройка использования образа registry.local/k8s-c10f1/pause:3.9 при запуска pod'ов в podman (podman pod init)
</pre>

Проверьте содержимое файла /etc/containers/policy.json скопированного с мастер-узла:
<pre>
{
  "default": [
    {
      "type": "reject"
    }
  ],
  "transports": {
    "docker": {
      "registry.local": [
        {
          "type": "signedBy",
          "keyType": "GPGKeys",
          "keyPath": "/var/sigstore/keys/imagemaker.pgp"
        }
      ]
    }
  }
}
</pre>

Проверьте наличие открытого ключа `imagemaker.pgp` в каталоге `/var/sigstore/`:
<pre>
└── keys
    ├── imagemaker.pgp
    └── policy.json
</pre>

### Установка тропы PATH поиска исполняемых команд

Измените переменную PATH:

<pre>
export PATH=/usr/libexec/podsec/u7s/bin/:$PATH
</pre>

### Подключение worker-узла

Скопируйте команду подключния `worker-узла`, полученную на этапе установки начального `master-узла`.  Запустите ее:

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

### Проверка состояния процессов

Проверьте состояние дерева процессов:
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

Все остальные процессы `kube-proxy`, `kube-flannel` запускаются как контейнеры от соответствующих образов `registry.local/k8s-c10f1/kube-proxy:v1.26.3`, `registry.local/k8s-c10f1/flannel:v0.19.2`.

6. Зайдите на `master-узел` и проверьте подключение `worker-узла`:
```
# kubectl get nodes -o wide
NAME       STATUS   ROLES           AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                 KERNEL-VERSION         CONTAINER-RUNTIME
host-212   Ready    control-plane   7h54m   v1.26.3   10.96.0.1     <none>        ALT SP Server 11100-01   5.15.105-un-def-alt1   cri-o://1.26.2
host-226   Ready    <none>          8m30s   v1.26.3   10.96.0.1     <none>        ALT SP Server 11100-01   5.15.105-un-def-alt1   cri-o://1.26.2
```

### Запуск сетевого маршрутизатора для контейекров kube-flannel

На `master-узле` под пользоваталем `root` выполните команду:

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

На `master-узле` выполните команду:
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

Выполните все пункты из главы *Установка master-узла* до раздела *Инициализация мастер-узла*.

#### Инициализация мастер-узла  при работа с балансировщиков haproxy

При установке начального master-узла необходимо параметром `control-plane-endpoint` указать URL  балансировщика `haproxy`:
```
# kubeadm init --apiserver-advertise-address 192.168.122.80 --control-plane-endpoint <IP_адрес_haproxy>:8443
```

При запуске в параметре `--apiserver-advertise-address` укажите IP-адрес API-интерфейса `kube-apiserver`.
**Этот адрес должен отличаться от IP-адреса регистратора и WEB-сервера подписей.**

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

#### Настройка репозиторий обновления

Настройте репозиторий обновления
<pre>
apt-repo add 'rpm [p10] http://ftp.altlinux.org/pub/distributions/ALTLinux p10/branch/x86_64 classic'
apt-repo add 'rpm [p10] http://ftp.altlinux.org/pub/distributions/ALTLinux p10/branch/x86_64-i586 classic'
apt-repo add 'rpm [p10] http://ftp.altlinux.org/pub/distributions/ALTLinux p10/branch/noarch classic'
rm -f /etc/apt/sources.list.d/sources.list
apt-get update
</pre>

### Установка podsec-пакетов:

Установите podsec-пакеты версии *0.9.38-alt1* и выше:

```
# apt-get install -y podsec-0.9.38-alt1.noarch.rpm  podsec-k8s-rbac-0.9.38-alt1.noarch.rpm podsec-k8s-0.9.38-alt1.noarch.rpm  podsec-inotify-0.9.38-alt1.noarch.rpm
```

### Настройка политики контейнеризации

Вызовите команду:
<pre>
# podsec-create-policy 192.168.122.70 # ip-aдрес_регистратора и WEB-сервера подписей
Добавление привязки доменов registry.local sigstore.local к IP-адресу 192.168.122.70
Создание группы podman
Инициализация каталога /var/sigstore/ и подкаталогов хранения открытых ключей и подписей образов
Создание каталога и подкаталогов  /var/sigstore/
Создание с сохранением предыдущих файла политик /etc/containers/policy.json
Создание с сохранением предыдущих файл /etc/containers/registries.d/default.yaml описания доступа к открытым ключам подписантов
Добавление insecure-доступа к регистратору registry.local в файле /etc/containers/registries.conf
Настройка использования образа registry.local/k8s-c10f1/pause:3.9 при запуска pod'ов в podman (podman pod init)
</pre>

Проверьте содержимое файла /etc/containers/policy.json скопированного с мастер-узла:
<pre>
{
  "default": [
    {
      "type": "reject"
    }
  ],
  "transports": {
    "docker": {
      "registry.local": [
        {
          "type": "signedBy",
          "keyType": "GPGKeys",
          "keyPath": "/var/sigstore/keys/imagemaker.pgp"
        }
      ]
    }
  }
}
</pre>

Проверьте наличие открытого ключа `imagemaker.pgp` в каталоге `/var/sigstore/`:

<pre>
└── keys
    ├── imagemaker.pgp
    └── policy.json
</pre>

### Установка тропы PATH поиска исполняемых команд

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
kube-flannel   daemonset.apps/kube-flannel-ds   2         2         2       3            3           <none>                   153m   kube-flannel   registry.local/k8s-c10f1/flannel:v0.19.2      app=flannel
kube-system    daemonset.apps/kube-proxy        2         2         2       2            2           kubernetes.io/os=linux   174m   kube-proxy     registry.local/k8s-c10f1/kube-proxy:v1.26.3   k8s-app=kube-proxy
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

Логи обращений и балансировку запросов между узлами можно посмотреть командой:
```
# tail -f /var/log/haproxy.log
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


