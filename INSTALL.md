# Общее описание {#общее_описание}

Запуск `Kubernetes` в режиме `rootless` обеспечивает запуск `Pod`ов без
системных `root`-привелегий в рамках `user namespace` системного
пользователя `u7s-admin`. Работа в этом режиме практически не требует
никаких модификаций, но обеспечивает повышенные уровень защищенности
`kubernetes`, так как клиентские приложения даже при использовании
уязвимостей не могут получить права пользователя `root` и нарушить
работу узла.

Запуск `kubernetes` версий `1.26.x` в режиме `rootless` обеспечивает
пакет `podsec-k8s` версии `1.0.2` или выше.

Запуск `kubernetes` версий `1.26.x` и старше (1.27, \..., 1.31 ) в
режиме `rootless` с возможностью указания номера устанавливаемой версии
(см. раздел *Выбор версии kubernetes, имени регистратора и платформы*)
обеспечивает пакет `podsec-k8s` версии `1.1` или выше.

**Для разворачивания `rootless kubernetes` требуются ядра ядрах *5.15* и
выше.**

# podsec-k8s - Быстрый старт {#podsec_k8s___быстрый_старт} 

## Установка master-узла <a id='установка_master_узла'></a>{#установка_master_узла}

### Инициализация master-узла {#инициализация_master_узла}

Для запуска `kubernetes` в режиме `rootless` установите пакет
`podsec-k8s` версии `1.0.5` или выше.

    apt-get install podsec-k8s

Измените переменную PATH:

    export PATH=/usr/libexec/podsec/u7s/bin/:$PATH

В каталоге `/usr/libexec/podsec/u7s/bin/` находятся программы,
обеспечивающие работы `kubernetes` в `rootless`-режиме.

Для разворачивания `master-узла` запустите команду:

    kubeadm init

> По умолчанию уровень отладки устанавливается в `0`. Если необходимо
> увеличить уровень отладки укажите перед подкомандой `init` флаг
> `-v n`. Где `n` принимает значения от `0` до `9`-ти.

После:

- генерации сертификатов в каталоге `/etc/kubernetes/pki`,
- загрузки образов,
- генерации conf-файлов в каталоге `/etc/kubernetes/manifests/`,
  `/etc/kubernetes/manifests/etcd/`
- запуска сервиса `kubelet` и `Pod`'ов системных `kubernetes-образов`

инициализируется `kubernet-кластер` из одного узла.

По окончании скрипт выводит строки подключения `master`(`Control Plane`)
и `worker-узлов`:

    You can now join any number of control-plane nodes by copying certificate authorities
    and service account keys on each node and then running the following as root:

    kubeadm join xxx.xxx.xxx.xxx:6443 --token ... --discovery-token-ca-cert-hash sha256:.. --control-plane

    Then you can join any number of worker nodes by running the following on each as root:

    kubeadm join xxx.xxx.xxx.xxx:6443 --token ... --discovery-token-ca-cert-hash sha256:...

### Запуск сетевого маршрутизатора для контейенеров kube-flannel {#запуск_сетевого_маршрутизатора_для_контейенеров_kube_flannel}

` Для версии ``podsec 1.0.8`` и выше этот шаг выполнять не надо - он выполняется во время ``kubeadm init``.`

Для перевода узла в состояние `Ready`, запуска `coredns` `Pod`'ов
запустите `flannel`.

На `master-узле` под пользоваталем `root` выполните команду:

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

После завершения скрипта в течении минуты настраиваются сервисы
мастер-узла кластера. По ее истечении проверьте работу `usernetes`
(`rootless kuber`)

### Проверка работы master-узла {#проверка_работы_master_узла}

На `master-узле` выполните команду:

    # kubectl get daemonsets.apps -A
    NAMESPACE      NAME              DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
    kube-flannel   kube-flannel-ds   1         1         1       1            1           &lt;none&gt;                   102s
    kube-system    kube-proxy        1         1         1       1            1           kubernetes.io/os=linux   8h

Число `READY` каждого `daemonset` должно быть равно числу `DESIRED` и
должно быть равно числу узлов кластера.

    # kubectl get nodes -o wide
    NAME       STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE           KERNEL-VERSION         CONTAINER-RUNTIME
    &lt;host>     Ready    control-plane   16m   v1.26.3   10.96.0.1     <none>        ALT SP Server 11100-01   5.15.105-un-def-alt1   cri-o://1.26.2

Проверьте работу `usernetes` (`rootless kuber`)

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

Состояние всех `Pod`'ов должны быть в `1/1`.

Проверьте состояние дерева `rootless-процессов`:

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

Процесс `kubelet` запускается как сервис в `user namespace` процесса
`rootlesskit`.

Все остальные процессы `kube-controller`, `kube-apiserver`,
`kube-scheduler`, `kube-proxy`, `etcd`, `coredns` запускаются как
контейнеры от соответствующих образов в `user namespace` процесса
`rootlesskit`.

### Обеспечение запуска обычных POD'ов на мастер-узле {#обеспечение_запуска_обычных_podов_на_мастер_узле}

По умолчанию на master-узле пользовательские `Pod`ы не запускаются.
Чтобы снять это ограничение наберите команду:

    # kubectl taint nodes &lt;host&gt; node-role.kubernetes.io/control-plane:NoSchedule-

Вывод команды:

    node/&lt;host&gt; untainted

Где `<host>`{=html} - имя master-узла, отображаемое в выводе команды:

    # kubectl get nodes

## Инициализация и подключение worker-узла {#инициализация_и_подключение_worker_узла}

Установите пакет `podsec-k8s`:

    apt-get install podsec-k8s

Измените переменную PATH:

    export PATH=/usr/libexec/podsec/u7s/bin/:$PATH

### Подключение worker-узлов {#подключение_worker_узлов}

Скопируйте команду подключения `worker-узла`, полученную на этапе
установки начального `master-узла`. Запустите ее:

    kubeadm join xxx.xxx.xxx.xxx:6443 --token ... --discovery-token-ca-cert-hash sha256:...

> По умолчанию уровень отладки устанавливается в `0`. Если необходимо
> увеличить уровень отладки укажите перед подкомандой `join` флаг
> `-v n`. Где `n` принимает значения от `0` до `9`-ти.

По окончании скрипт выводит текст:

    This node has joined the cluster:
    * Certificate signing request was sent to apiserver and a response was received.
    * The Kubelet was informed of the new secure connection details.

    Run 'kubectl get nodes' on the control-plane to see this node join the cluster.

### Проверка состояния процессов {#проверка_состояния_процессов}

Проверьте состояние дерева `rootless-процессов`:

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

Процесс `kubelet` запускается как сервис в `user namespace` процесса
`rootlesskit`.

Все остальные процессы `kube-proxy`, `kube-flannel` запускаются как
контейнеры от соответствующих образов в `user namespace` процесса
`rootlesskit`.

### Проверка готовности master и worker узлов kubernets {#проверка_готовности_master_и_worker_узлов_kubernets}

Зайдите на `master-узел` и проверьте подключение `worker-узла`:

</li>
</ol>

    # kubectl get nodes -o wide
    NAME       STATUS   ROLES           AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                 KERNEL-VERSION         CONTAINER-RUNTIME
    &lt;host1>   Ready    control-plane   7h54m   v1.26.3   10.96.0.1     &lt;none&gt;  ALT   cri-o://1.26.2
    &lt;host2>   Ready    &lt;none&gt;          8m30s   v1.26.3   10.96.0.1     &lt;none&gt;  ALT   cri-o://1.26.2
    ...

## Инициализация и подключение дополнительных master-узлов {#инициализация_и_подключение_дополнительных_master_узлов}

Установите пакет `podsec-k8s`:

    apt-get install podsec-k8s

Измените переменную PATH:

    export PATH=/usr/libexec/podsec/u7s/bin/:$PATH

### Подключение master-узлов {#подключение_master_узлов}

Скопируйте команду подключения `master-узла`, полученную на этапе
установки начального `master-узла`. Она отличается от команды
подключения `worker`-узлов наличием дополнительных параметров
`--control-plane`, `--certificate-key`.

Запустите ее:

    kubeadm join xxx.xxx.xxx.xxx:6443 --token ... --discovery-token-ca-cert-hash sha256:...
      --control-plane --certificate-key ...

> По умолчанию уровень отладки устанавливается в `0`. Если необходимо
> увеличить уровень отладки укажите перед подкомандой `join` флаг
> `-v n`. Где `n` принимает значения от `0` до `9`-ти.

По окончании скрипт выводит текст:

    This node has joined the cluster and a new control plane instance was created:

    * Certificate signing request was sent to apiserver and approval was received.
    * The Kubelet was informed of the new secure connection details.
    * Control plane label and taint were applied to the new node.
    * The Kubernetes control plane instances scaled up.
    * A new etcd member was added to the local/stacked etcd cluster.

### Проверка состояния процессов {#проверка_состояния_процессов_1}

Проверьте состояние дерева процессов:

    # pstree
    ...
            ├─systemd─┬─(sd-pam)
            │         ├─dbus-daemon
            │         ├─kubelet.sh───nsenter_u7s───nsenter───_kubelet.sh───kubelet───11*[{kubelet}]
            │         └─rootlesskit.sh───rootlesskit─┬─exe─┬─conmon───kube-controller───4*[{kube-controller}]
            │                                        │     ├─conmon───kube-scheduler───8*[{kube-scheduler}]
            │                                        │     ├─conmon───etcd───9*[{etcd}]
            │                                        │     ├─conmon───kube-proxy───4*[{kube-proxy}]
            │                                        │     ├─conmon───kube-apiserver───8*[{kube-apiserver}]
            │                                        │     ├─rootlesskit.sh───crio───8*[{crio}]
            │                                        │     └─7*[{exe}]
            │                                        ├─slirp4netns
            │                                        └─8*[{rootlesskit}]

Дерево `rootless-процессов` должно отличаться от дерева процессов
основного `master-узла` отсутствием контейнеров `coredns`.

### Проверка готовности master и worker узлов kubernets {#проверка_готовности_master_и_worker_узлов_kubernets_1}

На одном из master-узлов наберите команду:

    # kubectl get nodes -o wide
    NAME       STATUS   ROLES           AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                 KERNEL-VERSION         CONTAINER-RUNTIME
    &lt;host1>   Ready    control-plane   7h54m   v1.26.3   10.96.0.1     &lt;none&gt;        ALT    cri-o://1.26.2
    &lt;host2>   Ready    &lt;none&gt;          8m30s   v1.26.3   10.96.0.1     &lt;none&gt;  ALT   cri-o://1.26.2
    ...
    &lt;hostN>   Ready    control-plane   55m     v1.26.3   10.96.122.&lt;N> <none>        ALT      cri-o://1.26.2
    ...

### Использование REST-интерефейсов подключенных master-узлов {#использование_rest_интерефейсов_подключенных_master_узлов}

По умолчанию на подключенных `master-узлах` в файле
`/etc/kubernetes/admin.conf` указан адрес `API-интерфейса` основного
`master-узла`:

    apiVersion: v1
    clusters:
    - cluster:
        ...
        server: https://<master1>:6443
    ...

Для балансировки нагрузки в файлах конфигурации `~user/.kube/config`
есть смысл указать адреса `API-интерфейсов` дополнительных
`master-узлов`:

    apiVersion: v1
    clusters:
    - cluster:
        ...
        server: https://<masterN>:6443
    ...

## Создание гетерогенных кластеров, миграция с rootfull кластеров на rootless кластера {#создание_гетерогенных_кластеров_миграция_с_rootfull_кластеров_на_rootless_кластера}

В рамках одного кластера могут функционировать как `rootfull` узла\`,
так и `rootless узлы`. Например имеет смысл в расках `rootfull` кластера
для повышения защищенности кластера подключать в качестве `Worker`оа
`rootless` узлы.

Перед подключением \`rootless\` узлов необходимо выполнить определенные
действия.

### Запуск kube-proxy на rootless-узле в rootfull кластере {#запуск_kube_proxy_на_rootless_узле_в_rootfull_кластере}

Для запуска `kube-proxy` на `rootless-узле` в `rootfull кластере` на
`ControlPlane` узле:

- Наберите команду редактирования `ConfigMap`а `kube-proxy`:

<!-- -->

    kubectl -n kube-system edit Configmaps kube-proxy

- Измение в элементе `data.config.conf` значение переменной
  `conntrack.maxPerCore` с `null` на `0`.

<!-- -->

- Выйдите из редактора

### Запуск ControlPlane узла на rootless-узле в rootfull кластере {#запуск_controlplane_узла_на_rootless_узле_в_rootfull_кластере}

Для запуска `ControlPlane` на `rootless-узле` в `rootfull кластере` на
`ControlPlane` узле:

- Наберите команду редактирования `ConfigMap`а `kubeadm-config`:

<!-- -->

    kubectl -n kube-system edit  Configmaps kubeadm-config

- Измение в элементе `data.ClusterConfiguration` значение переменной
  `etcd.local.dataDir` с `/var/lib/etcd` на `/var/lib/podsec/u7s/etcd`.

<!-- -->

- Выйдите из редактора

## Получениe строки подключения узла к кластеру {#получениe_строки_подключения_узла_к_кластеру}

### Получении строки подключения Worker узла к кластеру {#получении_строки_подключения_worker_узла_к_кластеру}

В случае, если команда строки подключения утеряна или срок
сгенерированного сертификата истек можно сгенерировать новую строку
подключения, выполнив команду:

    joinCommand=$(/usr/bin/kubeadm token create --print-join-command)

и выполнить команду подключения:

    export PATH=/usr/libexec/podsec/u7s/bin/:$PATH
    $joinCommand

### Получении строки подключения Control-plane узла к кластеру {#получении_строки_подключения_control_plane_узла_к_кластеру}

В определенных случаях \`kubeadm init\` генерирует только строку
подключения \`worker\` узлов. Или срок действия сертификата для
подключения истек.

В этом случае есть смысл перегенерировать сертификат:

    cert=$(/usr/bin/kubeadm init phase upload-certs --upload-certs 2>/dev/null | tail -1)

строку подключения \`control-plane\` и \`worker\` узлов к кластеру:

    joinCommand=$(/usr/bin/kubeadm token create --print-join-command)

и выполнить команду подключения:

    export PATH=/usr/libexec/podsec/u7s/bin/:$PATH
    $joinCommand --control-plane --certificate-key $cert

См. [How do I find the join command for kubeadm on the
master?](https://stackoverflow.com/questions/51126164/how-do-i-find-the-join-command-for-kubeadm-on-the-master)

## Системный пользователь u7s-admin {#системный_пользователь_u7s_admin}

Все контейнеры в `rootless kubernetes`. включая системные работают от
имени системного пользователя `u7s-admin`. Вы можете для мониторинга
работы системы или запуска дополнительного функционала работать в
системе от имени этого пользователя.

Для входа в терминальный режим этого пользователя достаточно в
пользователе с правами `root` набрать команду:

    # machinectl shell u7s-admin@ /bin/bash

или задав пароль пользователя:

    # passwd u7s-admin

зайти в него через `ssh`.

Для входа в namespace пользователя наберите команду :

    $ nsenter_u7s
    #

В рамках своего `namespace` пользователь `u7s-admin` имеет права `root`,
оставаясь в рамках системы с правам пользователя `u7s-admin`.

Наличие прав `root` позволает использовать системные команды,требующих
`root-привелегий` для работы с сетевым, файловым окружением (эти
окружения отличаются от системных): `ip`, `iptables`, `crictl`, \...

С помощью команды `crict`l можно

- посмотреть наличие образов в системном кэше,
- удалить, загрузить образы
- посмотреть состояние контейнеров, pod\'ов
- и т.п.

Кроме этого `namespace` пользователя `u7s-admin` присутствуют файлы и
каталоге созданные в рамках данного `namespace` и отсутствующие в
основной системе. Например Вы можете посмотреть логи контейнеров в
каталоге `/var/log/pods` и т.п.

## Особенности разворачивания приложений в rootless kubernetes {#особенности_разворачивания_приложений_в_rootless_kubernetes}

При использовании сервисов типа `NodePort` поднятые в рамках кластера
порты в диапазоне `30000-32767` остаются в `namespace` пользователя
`u7s-admin`. Для их проброса наружу необходимо в пользователе
`u7s-admin` запустить команду:

    $ nsenter_u7s rootlessctl add-ports 0.0.0.0:&lt;port>:&lt;port>/tcp

Сервисы типа `NodePort` из за их небольшого диапазона и
\"нестабильности\" портов при переносе решения в другой кластер довольно
редко используются. Рекомендуется вместо них использовать сервисы типа
`ClusterIP` c доступом к ним через `Ingress`-контроллеры.

# Разворачивание rootless kubernetes кластера с балансировщиком REST-запросов haproxy {#разворачивание_rootless_kubernetes_кластера_с_балансировщиком_rest_запросов_haproxy}

Вышеописанный процесс разворачивания обеспечивать только ручную
балансировку запросов: [840px\|\|center\|rootless kubernetes-кластер без
балансировщика
haproxy](Файл:Variant1.drawio.png "840px||center|rootless kubernetes-кластер без балансировщика haproxy"){.wikilink}

Ручная балансировка запросов к `API-интерфейсам` `master-узлов` путем
указания у клиентов адресов различных `master-узлов` довольно неудобна,
так как не обеспечивает равномерного распределения запросов по узлам
кластера и не обеспечивает автоматической отказоустойчивости при выходе
из строя `master-узлов`.

Решает данную проблему установка балансировщика нагрузки `haproxy`.
[840px\|\|center\|rootless kubernetes-кластер без балансировщика
haproxy](Файл:Variant_haproxy_1.drawio.png "840px||center|rootless kubernetes-кластер без балансировщика haproxy"){.wikilink}

Перевод кластера в режим балансировки запросов через haproxy возможен.
Подробности описаны в статье [How to convert a Kubernetes non-HA control
plane into an HA control
plane?](https://stackoverflow.com/questions/65505137/how-to-convert-a-kubernetes-non-ha-control-plane-into-an-ha-control-plane),
но данная процедура не гарантирует корректный перевод на всех версиях
`kubernetes` и ее не рекомендуют применять на `production` кластерах.

Так что наиболее надежным способом создания кластера с балансировкой
запросов является создание нового кластера.

## Настройка балансировщика REST-запросов haproxy {#настройка_балансировщика_rest_запросов_haproxy}

Балансировщик `REST-запросов haproxy` можно устанавливать как на
отдельный сервер, так на один из серверов кластера.
[840px\|center\|безрамки](Файл:Variant_haproxy_master.drawio.png "840px|center|безрамки"){.wikilink}

> **Если балансировщик устанавливается на `rootless` сервер кластера, то
> для балансировщика необходимо выделить отдельный IP-адрес. Если на
> этом же сервере функционируют локальный регистратор (`registry.local`)
> и сервер подписей (`sigstore.local`), то IP-адрес балансировщика может
> совпадать c IP-адресами этих сервисов.**

> **Если планируется создание отказоустойчивого решения на основе
> нескольких серверов `haproxy`, то для них кроме собственного
> `IP-адреса` необходимо будет для всех серверов `haproxy` выделить один
> общий `IP-адрес`, который будет иметь `master-балансировщик`.**

Полная настройка отказоустойчивого кластера `haproxy` из 3-х узлов
описана в документе [ALT Container OS подветка K8S. Создание HA
кластера](https://www.altlinux.org/ALT_Container_OS_%D0%BF%D0%BE%D0%B4%D0%B2%D0%B5%D1%82%D0%BA%D0%B0_K8S._%D0%A1%D0%BE%D0%B7%D0%B4%D0%B0%D0%BD%D0%B8%D0%B5_HA_%D0%BA%D0%BB%D0%B0%D1%81%D1%82%D0%B5%D1%80%D0%B0).

Здесь же мы рассмотрим создание и настройка с одним сервером `haproxy` с
балансировкой запросов на `master`-узлы.

Установите пакет `haproxy`:

    # apt-get install haproxy

Отредактируйте конфигурационный файл `/etc/haproxy/haproxy.cfg`:

- добавьте в него описание `frontend`'a `main`, принимающего запросы по
  порту `8443`:
       frontend main
        bind *:8443
        mode tcp
        option tcplog
        default_backend apiserver
- добавьте описание `backend`'а `apiserver`:
      backend apiserver
        option httpchk GET /healthz
        http-check expect status 200
        mode tcp
        option ssl-hello-chk
        balance     roundrobin
            server master01 &lt;IP_или_DNS_начального_мастер_узла>:6443 check
- запустите `haproxy`:

<!-- -->

    # systemctl enable haproxy
    # systemctl start haproxy

## Инициализация master-узла {#инициализация_master_узла_1}

#### Инициализация мастер-узла при работа с балансировщиков haproxy {#инициализация_мастер_узла_при_работа_с_балансировщиков_haproxy}

При установке начального master-узла необходимо параметром
`control-plane-endpoint` указать URL балансировщика `haproxy`:

    # kubeadm init --apiserver-advertise-address 192.168.122.80 --control-plane-endpoint &lt;IP_адрес_haproxy&gt;:8443

При запуске в параметре `--apiserver-advertise-address` укажите IP-адрес
API-интерфейса `kube-apiserver`.

**IP-адреса в параметрах** `--apiserver-advertise-address` **и**
`--control-plane-endpoint` **должны отличаться. Если Вы развернули**
`haproxy` **на том же мастер-узле, поднимите на сетевом нтерфейсе
дополнительный IP-адрес и укажите его в параметре**
`--control-plane-endpoint`\'\'\'.

В результате инициализации `kubeadm` выведет команды подключения
дополнительных `control-plane` и `worker` узлов:

    ...
    You can now join any number of the control-plane node running the following command on each as root:

    kubeadm join &lt;IP_адрес_haproxy>:8443 --token ... \
            --discovery-token-ca-cert-hash sha256:... \
            --control-plane --certificate-key ...

    Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
    As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use
    "kubeadm init phase upload-certs --upload-certs" to reload certs afterward.

    Then you can join any number of worker nodes by running the following on each as root:

    kubeadm join <IP_адрес_haproxy>:8443 --token ... \
            --discovery-token-ca-cert-hash sha256:...
    ...

Обратите внимание - в командах присоединения узлов указывается не URL
созданного начального master-узла
(`<IP_или_DNS_начального_мастер_узла>:6443`), а URL `haproxy`.

В сформированных файлах конфигурации `/etc/kubernetes/admin.conf`,
`~/.kube/config` также указывается URL `haproxy`:

    apiVersion: v1
    clusters:
    - cluster:
    ...
        server: https://&lt;IP_адрес_haproxy>:8443

То есть вся работа с кластеров в дальнейшем идет через балансировщик
запросов `haproxy`.

Для перевода узла в состояние `Ready`, запуска coredns Pod'ов запустите
flannel

#### Запуск сетевого маршрутизатора для контейнеров kube-flannel {#запуск_сетевого_маршрутизатора_для_контейнеров_kube_flannel}

На `master-узле` под пользоваталем `root` выполните команду:

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

После завершения скрипта в течении минуты настраиваются сервисы
мастер-узла кластера. По ее истечении проверьте работу `usernetes`
(`rootless kuber`)

## Подключение дополнительных master-узлов {#подключение_дополнительных_master_узлов}

### Установка тропы PATH поиска исполняемых команд {#установка_тропы_path_поиска_исполняемых_команд}

Измените переменную `PATH`:

    export PATH=/usr/libexec/podsec/u7s/bin/:$PATH

### Подключение master (control plane) узла {#подключение_master_control_plane_узла}

Скопируйте строку подключения `control-plane` узла и вызовите ее:

    # kubeadm join &lt;IP_адрес_haproxy&gt;:8443 --token ... \
            --discovery-token-ca-cert-hash sha256:... \
            --control-plane --certificate-key ...

В результате работы команда kubeadm выведет строки:

     This node has joined the cluster and a new control plane instance was created:

    * Certificate signing request was sent to apiserver and approval was received.
    * The Kubelet was informed of the new secure connection details.
    * Control plane label and taint were applied to the new node.
    * The Kubernetes control plane instances scaled up.
    * A new etcd member was added to the local/stacked etcd cluster.
    ...
    Run 'kubectl get nodes' to see this node join the cluster.

Наберите на вновь созданном (или начальном)`control-plane` узле команду:

    # kubectl  get nodes
    NAME       STATUS   ROLES           AGE     VERSION
    &lt;host1&gt;   Ready    control-plane   4m31s   v1.26.3
    &lt;host2&gt;   Ready    control-plane   26s     v1.26.3

Обратите внимание, что роль (ROLES) обоих узлов - `control-plane`.

Наберите команду:

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
    kube-flannel   daemonset.apps/kube-flannel-ds   2         2         2       3            3           <none>                   153m   kube-flannel   registry.local/k8s-c10f2/flannel:v0.19.2      app=flannel
    kube-system    daemonset.apps/kube-proxy        2         2         2       2            2           kubernetes.io/os=linux   174m   kube-proxy     registry.local/k8s-c10f2/kube-proxy:v1.26.3   k8s-app=kube-proxy
    ...

Убедитесь, что сервисы `pod/etcd`, `kube-apiserver`,
`kube-controller-manager`, `kube-scheduler`, `kube-proxy`,
`kube-flannel` запустились на обоих control-plane узлах.

### Добавление master-узла в балансироващик haproxy {#добавление_master_узла_в_балансироващик_haproxy}

Для балансировки запросов по двум серверам добавьте URL подключенного
`control-plane` узла в файл конфигурации `/etc/haproxy/haproxy.cfg`:

    backend apiserver
        option httpchk GET /healthz
        http-check expect status 200
        mode tcp
        option ssl-hello-chk
        balance     roundrobin
            server master01 &lt;IP_или_DNS_начального_мастер_узла>:6443 check
            server master02 &lt;IP_или_DNS_подключенного_мастер_узла>:6443 check

и перезапустите `haproxy`:

    # systemctl restart haproxy

Логи обращений и балансировку запросов между узлами можно посмотреть
командой:

    # tail -f /var/log/haproxy.log

## Подключение worker-узлов {#подключение_worker_узлов_1}

Подключение дополнительных worker-узлов происходит аналогично описанному
выше в главе **Инициализация и подключение worker-узла**.

## Настройка отказоустойчивого кластера серверов haproxy, keepalived {#настройка_отказоустойчивого_кластера_серверов_haproxy_keepalived}

### Масштабирование haproxy, установка пакетов {#масштабирование_haproxy_установка_пакетов}

Если необходимо создать отказоустойчивое решение допускающее выход
`haproxy`-севрера из строя установите `haproxy` на несколько серверов.
Файлы конфигурации `<code>`{=html}haproxy\<.code\> на всех сервервх
должны быть идентичны.

Для контроля доступности `haproxy` и переназначений виртуального адреса
дополнительно установите на каждом сервис `keepalived`:

    # apt-get install haproxy keepalived

### Конфигурирование keepalived {#конфигурирование_keepalived}

[840px\|безрамки\|центр\|kubeenetes кластер с haproxy и
keepalived](Файл:Variant_haproxy_keepalived.png "840px|безрамки|центр|kubeenetes кластер с haproxy и keepalived"){.wikilink}

Создайте файл конфигурации \'keepalived\'
*/etc/keepalived/keepalived.conf*:

`! /etc/keepalived/keepalived.conf`\
`! Configuration File for keepalived`\
`global_defs {`\
`    router_id LVS_K8S`\
`}`\
`vrrp_script check_apiserver {`\
`  script "/etc/keepalived/check_apiserver.sh"`\
`  interval 3`\
`  weight -2`\
`  fall 10`\
`  rise 2`\
`}`

`vrrp_instance VI_1 {`\
`    state MASTER`\
`    interface br0`\
`    virtual_router_id  51`\
`    priority 101`\
`    authentication {`\
`        auth_type PASS`\
`        auth_pass 42`\
`    }`\
`    virtual_ipaddress {`\
`        10.150.0.160`\
`    }`\
`    track_script {`\
`        check_apiserver`\
`    }`\
`}`

На одном из узлов установите параметр *state* в значение *MASTER* и
параметр *priority* в значение *101*. На остальных параметр *state* в
значение *BACKUP* и параметр *priority* в значение *100*.

Скрипт */etc/keepalived/check_apiserver.sh* проверяет доступность
балансировщика *haproxy*:

`#!/bin/sh`

`errorExit() {`\
`    echo "*** $*" 1>&2`\
`    exit 1`\
`}`

`APISERVER_DEST_PORT=8443`\
`APISERVER_VIP=10.150.0.160`\
`curl --silent --max-time 2 --insecure `[`https://localhost:${APISERVER_DEST_PORT}/`](https://localhost:$%7BAPISERVER_DEST_PORT%7D/)` -o /dev/null || errorExit "Error GET `[`https://localhost:${APISERVER_DEST_PORT}/`](https://localhost:$%7BAPISERVER_DEST_PORT%7D/)`"`\
`if ip addr | grep -q ${APISERVER_VIP}; then`\
`    curl --silent --max-time 2 --insecure `[`https://${APISERVER_VIP}:${APISERVER_DEST_PORT}/`](https://$%7BAPISERVER_VIP%7D:$%7BAPISERVER_DEST_PORT%7D/)` -o /dev/null || errorExit "Error GET `[`https://${APISERVER_VIP}:${APISERVER_DEST_PORT}/`](https://$%7BAPISERVER_VIP%7D:$%7BAPISERVER_DEST_PORT%7D/)`"`\
`fi`

Параметр *APISERVER_DEST_PORT* задает порт балансировщиков *haproxy*,
параметр *APISERVER_VIP* виртуальный адрес, через который будут
взаимодействовать *master* (*control plane*) узлы кластера *k8s*.

Скрипт проверяет работоспособность *haproxy* на локальной машине.

Подробности см. на
[https://www.altlinux.org/Keepalived](https://www.altlinux.org/Keepalived "https://www.altlinux.org/Keepalived"){.wikilink}
А если в настоящее время виртуальный адрес принадлежит текущему узлу, то
и работоспособность *haproxy* через виртуальный адрес.

Добавьте флаг на выполнение скрипта:

`chmod a+x /etc/keepalived/check_apiserver.sh`

При работающем балансировщике и хотя бы одному доступному порту *6443*
на *master-узлах* скрипт должен завершаться с кодом *0*.

Подробности см. на [Keepalived](Keepalived "Keepalived"){.wikilink}

# Установка и настройка ingress-контролера {#установка_и_настройка_ingress_контролера}

`Ingress-контроллер` обеспечивает переадресацию `http(s)` запросов по
указанным шаблонам на внутренние сервисы `kubernetes-кластера`. Для
`bare-metal` решений и решений на основе виртуальных машин наиболее
приемлимым является [ingress-nginx
контроллер](https://github.com/kubernetes/ingress-nginx).

При применении `Ingress-контроллера` нет необходимости создавать
`Nodeport-порты` и пробрасывать их из `namespace` пользователя
`u7s-admin`. `Ingress-контроллер` переадресует `http{s)` запрос через
сервис непосредственно на порты `Pod`\'ов входящих в реплики
`deployment`.

## Установка и настройка ingress-nginx-контролера в кластере {#установка_и_настройка_ingress_nginx_контролера_в_кластере}

[840px\|безрамки\|центр\|Использование
ingress-контроллера](Файл:Ingress.png "840px|безрамки|центр|Использование ingress-контроллера"){.wikilink}
Для установки `Ingress-контроллера` скопируйте его YAML-манифест:

    curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.0/deploy/static/provider/baremetal/deploy.yaml -o ingress-nginx-deploy.yaml

Выберите свободный порт в диапазона `30000 - 32767` (например `31000`) и
добавьте его в элемент `spec.ports.appProtocol==http` Yaml-описании
`kind==Service`:

    ...
    ---
    kind: Service
    spec:
      ports:
      - appProtocol: http
        ...
        nodePort: 31000
    ...

Если в Вашем решении используется ТОЛЬКО локальный регистратор
`registry.local`

- создайте алиасы образам nginx:

<!-- -->

    podman tag registry.k8s.io/ingress-nginx/controller:v1.8.0@sha256:744ae2afd433a395eeb13dc03d3313facba92e96ad71d9feaafc85925493fee3 registry.local/ingress-nginx/controller:v1.8.0
    podman tag registry.k8s.io/ingress-nginx/kube-webhook-certgen:v20230407@sha256:543c40fd093964bc9ab509d3e791f9989963021f1e9e4c9c7b6700b02bfb227b registry.local/ingress-nginx/kube-webhook-certgen:v20230407

и поместите их в локальный регистратор:

    podman push --tls-verify=false --sign-by='<EMAIL>' registry.local/ingress-nginx/controller
    podman push --tls-verify=false --sign-by='<EMAIL>' registry.local/ingress-nginx/kube-webhook-certgen

- исправьте имена образов в скачанном нанифесте на имена образов в
  локальном регистраторе.

Запустите Ingress-nginx-контролер:

    kubectl apply -f ingress-nginx-deploy.yaml

На одном или нескольких kubernet-узлах (эти узла в дальнейшем нужно
прописать в файле конфигурации балансировщика `haproxy`) пробросьте порт
`nginx-контроллера` (`31000`) из `namespace` пользователя `u7s-admin` в
сеть `kubernetes`:

    nsenter_u7s rootlessctl add-ports 0.0.0.0:31000:31000/tcp

### Настройка Ingress-правил {#настройка_ingress_правил}

Kubernetes поддерживает манифесты типа Ingress (kind: Ingress)
описывающие правила переадресации запросов URL http-запррса на
внутренние порты сервисов (kind: Service) kubernetes. Сервисы в свою
очередь перенаправляют запросы на реплики Pod\'ов, входящих в данный
сервис.

Общий вид Ingress-манифеста:

    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: <ingress_имя>
    spec:
      ingressClassName: nginx
      rules:
      - host: <домен_1>
        http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: <имя_сервиса_1>
                port:
                  number: 80
          - path: /<тропа_1>
            pathType: Prefix
            backend:
              service:
                name: <имя_сервиса_2>
                port:
                  number: 80
      - host: <домен_2>
        ...

Где:

- `host: ``<домен_1>`{=html}, `<домен_2>`{=html}, \... - домены
  WEB-серверов на которых приходит запрос;
- `path:/>`, `path:/``<тропа_1>`{=html} - тропы (префиксы запросов после
  домена)
- `pathType: Prefix` - тип троп: `Prefix` или `Exact`;
- `service:` - имя сервиса на который перенаправляется запрос, если
  полученный запрос соответсвует правилу;
- `port` - номер порта на который перенаправляется запрос.

Если запросу соответствует несколько правил, выбирается правило с
наиболее длинным префиксом.

Подробности смотри в [Kubernetes:
Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)

## Настройка haproxy и DNS {#настройка_haproxy_и_dns}

Добавьте в файлы конфигурации `haproxy` `/etc/haproxy/haproxy.conf`
переадресацию запросов на порт `80` (`http`) по IP-адресу балансировщика
haproxy на IP-адреса `kubernet-узлов` на которых выбранный порт
`nginx-контроллера` (`31000`) проброшен из `namespace` пользователя
`u7s-admin` в сеть `kubernetes`:

    frontend http
        bind *:80
        mode tcp
        option tcplog
        default_backend http

    backend http
        mode tcp
        balance     roundrobin
            server <server1> <ip1>:31000 check
            server <server2> <ip2>:31000 check

Заведите DNS-запись связывающую DNS-имя http-сервиса с IP-адресам
`haproxy`-сервера.

# Выбор версии kubernetes, имени регистратора и платформы {#выбор_версии_kubernetes_имени_регистратора_и_платформы}

Во время разворачивания узла командами

    kubeadm init
    kubeadm join ...

или при создании архива образов командой

    podsec-k8s-save-oci ...

есть возможность установкой переменных среды указать версию kubernetes,
имя регистратора и платформы:

- U7S_KUBEVERSION - версия kubernetes (v1.26.9, v1.27.7, \...);
- U7S_REGISTRY - имя регистратора (registry.k8s.io,
  registry.altlinux.org, registry.local);
- U7S_PLATFORM - имя платформы (k8s-c10f2, k8s-c10f1 , k8s-p10, \...)

## Выбор версии kubernetes {#выбор_версии_kubernetes}

Начиная с версии `1.0.9` поддерживается возможность выбора
устанавливаемой версии `kubernetes`.

### Указании версии основных kubernetes образов {#указании_версии_основных_kubernetes_образов}

Основные kubernetes-образы загружаются в момент инициализации узла
командой `kubeadm`. В список основных образов входят:

    kube-apiserver:<версия_kubernetes>
    kube-controller-manager:<версия_kubernetes>
    kube-scheduler:<версия_kubernetes>
    kube-proxy:<версия_kubernetes>
    pause:<версия__образа_pause>
    etcd:<версия__образа_etcd>
    coredns:<версия__образа_coredns>

Тег образов `kube-*` совпадает с полным номером версии kubernetes типа
v1.`<minor>`{=html}.`<patch>`{=html}. Например `v1.26.9`.

Теги образов `pause`, `etcd`, `coredns` \"зашиты\" как статические
переменные в `kubeadm` и могут отличаться в разных версиях `kubernetes`.

Получить список образов для текущей версии
\<code\<kuvernetes`</code>`{=html} можно командой:

    # /usr/bin/kubeadm  config images list 2>/dev/null

Пример вывода:

    registry.k8s.io/kube-apiserver:v1.26.10
    registry.k8s.io/kube-controller-manager:v1.26.10
    registry.k8s.io/kube-scheduler:v1.26.10
    registry.k8s.io/kube-proxy:v1.26.10
    registry.k8s.io/pause:3.9
    registry.k8s.io/etcd:3.5.9-0
    registry.k8s.io/coredns/coredns:v1.9.3

Выбор версии определяет переменная среды `U7S_KUBEVERSION`.

На `25.03.2024` при значении `U7S_REGISTRY` `registry.altlinux.org`
переменная `U7S_KUBEVERSION` может принимать следующие значения:

- Mинор версия v1.26:

` * ``v1.26.6``;`\
` * ``v1.26.9``;`\
` * ``v1.26.11``;`

- Mинор версия v1.27:

` * ``v1.27.11``;`

- Mинор версия v1.28:

` * ``v1.28.7``;`

Данный список относится к версиям регистратора `registry.altlinux.org`.
При использовании нативного регистратора `registry.k8s.io` (пустое
значение `export U7S_REGISTRY=`) можно указывать любую доступную на
`registry.k8s.io` версию.

Примеры:

    export U7S_REGISTRY=registry.altlinux.org
    export U7S_KUBEVERSION=v1.26.11

    export U7S_REGISTRY=registry.local
    export U7S_KUBEVERSION=v1.27.11

    export U7S_REGISTRY=
    export U7S_KUBEVERSION=v1.27.5

По умолчанию (при отсутствии значения переменной `U7S_KUBEVERSION`)
принимается максимальная версия образа `kube-apiserver` в рамках
минорной версии, которая определяется по минорной версии пакета
`kubeadm`.

Если номер указанной минорной версии `kubernetes` отличается от
текущего, при вызове команды `kubeadm` производится удаление текущих
`rpm-пакетов` `kubernetes*`, `cri-o` и установка `rpm-пакетов` указанной
версии.

Возможна ситуация, когда на регистраторе образов отсутствует версия
образа, полученная в результате выполнения команды:

    /usr/bin/kubeadm  config images list

Если в переменные среды добавить переменную:

    export U7S_SETAVAILABLEIMAGES=yes

то в качестве стандартного образа принимается образ с максимальной
версией в рамках данной минорной версии (`1.26`, `1.27`, `1.28`).
Данному образу присваивается тег, полученнфй в результате выполнения
команды `kubeadm config images`.

### Указании версии дополнительных kubernetes образов {#указании_версии_дополнительных_kubernetes_образов}

Кроме основных образов при разворачивании кластера используются
дополнительные образы:

- flannel:`<U7S_FLANNEL_TAG>`{=html};
- flannel-cni-plugin:`<U7S_FLANNELCNIPLUGIN_TAG>`{=html}
- cert-manager-webhook:`<U7S_CERTMANAGER_TAG>`{=html};
- cert-manager-controller:`<U7S_CERTMANAGER_TAG>`{=html};
- cert-manager-cainjector:`<U7S_CERTMANAGER_TAG>`{=html}.

Если переменным среды `U7S_FLANNEL_TAG`, `U7S_FLANNELCNIPLUGIN_TAG`,
`U7S_CERTMANAGER_TAG` не присвоены значения, то для каждого образа
определяется максимальная версия в регистраторе и загружается найденная
версия образа.

При необходимости можно изменить версию образа экпортировав перед
запускам команды соответствующую переменную. Например:

    export U7S_FLANNEL_TAG=v0.19.2

## Выбор исходного регистратора kubernetes-образов {#выбор_исходного_регистратора_kubernetes_образов}

Во время инициализации `master-узла` кластера (`kubeadm init`) или во
время подключения узла к кластеру (`kubeadm join`) команда `kubeadm`
может загружать образы с различных регистраторов образов и с различными
префиксами.

Выбор регистратора и префикса образов определяет переменная среды
`U7S_REGISTRY`. Если переменная не задана регистратор префикс
определяется автоматически на основе конфигурационных файлов
`/etc/os-release` и `/etc/hosts`.

Переменная среды `U7S_REGISTRY` может принимать следующие основные
значения:

- пустое значение;
- `registry.altlinux.org`;
- `registry.local`;
- \...

### Нативные kubernetes-образы {#нативные_kubernetes_образы}

    export U7S_REGISTRY=

Если переменная `U7S_REGISTRY` установлена в пустое значение образы
загружаются со стандартного регистратора образов `kubernetes`.

### Образы altlinux {#образы_altlinux}

#### Регистратор registry.altlinux.org {#регистратор_registry.altlinux.org}

    export U7S_REGISTRY=registry.altlinux.org

С регистратора `altlinux` устанавливаются образы при наличии доступа в
Интернет.

#### Локальный регистратор {#локальный_регистратор}

    export U7S_REGISTRY=registry.local

Локальный регистратор используется в сертифицированных дистрибутивах,
которые содержат kubernetes-образы на установочном диске.

Локальный регистратор образов `registry.local` может обеспечивать:

- разворачивание кластера без доступа в Интернет;
- ускоренное разворачивание как кластера, так и проектов,
  разворачиваемых в его рамках, так как образы необходимые для запуска
  `Pod`\'ов загружаются по локальной сети;
- высокий уровень защищенности системы путем установки политик
  разрешающих загрузку только подписанных образов и только с локального
  регистратора `registry.local`.

Пакет `podsec` обеспечивает:

- Установку на рабочих местах клиентов и узлах `kubernetes` политик
  доступа к образом для различных категория пользователей (скрипт
  `podsec-create-policy`).
- Разворачивание на одном узлов локального регистратора образов и
  сервера подписей образов (скрипт `podsec-create-services`).
- Загрузку с регистратора `registry.altlinux.org` образов необходимых
  для разворачивания `kubernetes` и формирования максимально сжатого
  (\<200Mb) архива. (скрипты `podsec-k8s-save-oci`, `podsec-save-oci`)
- разворачивание образов из архива, их подпись размещение на локальном
  регистраторе (скрипт `podsec-load-sign-oci`).

В зависимости от значения переменных `U7S_REGISTRY`, `U7S_PLATFORM`,
`U7S_KUBEVERSION` скрипт `podsec-k8s-save-oci` формирует архив образов
различных версий kubernetes:

- `registry.local/k8s-c10f2` - архив образов для сертифицированного
  дистрибутива `c10f` на основе набора образов с регистратора
  `registry.altlinux.org` с платформой `k8s-c10f2`;
- `registry.local/k8s-p10` - архив образов для несертифицированного
  дистрибутива `p10` на основе набора образов с регистратора
  `registry.altlinux.org` с платформой `k8s-p10`;

Локальный регистратор `registry.local` может также хранить подписанные
образы и запускаемых в рамках кластера проектов. Необходимо только,
чтобы каждый образ в рамках локального регистратор `registry.local` имел
префикс. Образы типа `registry.local/``<имя_образа>`{=html} не
допускаются, так как для них трудно определить \"подписанта\" образа.

##### podsec-create-policy - настройка политики доступа к образам различным категориям пользователей {#podsec_create_policy___настройка_политики_доступа_к_образам_различным_категориям_пользователей}

**Формат**:

    podsec-create-policy <ip-адрес_регистратора_и_сервера_подписей>

**Описание**:

Скрипт `podsec-create-policy` формирует в файлах
`/etc/containers/policy.json`,
`/etc/containers/registries.d/default.yaml` максимально защищенную
политику доступа к образам - по умолчанию допускается доступ только к
подписанным образам локального регистратора `registry.local`. Данная
политика распространяется как на пользователей имеющих права
суперпользователя, так и на пользователей группы `podsec`, создаваемые
podsec-скриптом `podsec-create-podmanusers`.

Пользователи группы `podsec-dev`, создаваемые podsec-скриптом
`podsec-create-imagemakeruser` имеют неограниченные права на доступ,
формирования образов, их подпись и помещение на локальный регистратор
`registry.local`.

В разворачиваниях kubernetes не требующих таких жестких ограничений в
политике доступа и работы с образами политики могут быть смягчены путем
модифицирования cистемных файлов политик `/etc/containers/policy.json`,
`/etc/containers/registries.d/default.yaml` или файлов установки политик
пользователей `~/.config/containers/policy.json`,
`~/.config/containers/registries.d/default.yaml`.

##### podsec-create-services - разворачивание локального регистратора образов и сервера подписей образов {#podsec_create_services___разворачивание_локального_регистратора_образов_и_сервера_подписей_образов}

Скрипт `podsec-create-services` обеспечивает разворачивание локального
регистратора образов и сервера подписей образов.

##### Загрузка образов, поддержка электронной подписи образов {#загрузка_образов_поддержка_электронной_подписи_образов}

###### Загрузка образов kubernetes {#загрузка_образов_kubernetes}

Для `kubernetes-образов`, хранящихся в архиве образов распаковку
образов, их подпись и размещение на локальном регистраторе
`registry.local` обеспечивает скрипт `podsec-load-sign-oci` запускаемый
пользователем группы `podsec-dev`.

Формат вызова команды:

    podsec-load-sign-oci <xz-архив-kubernetes-образов> <архитектура>  <e-mail-подписывающего>

###### Загрузка базовых образов {#загрузка_базовых_образов}

Кроме архива `kubernetes-образов` есть архив базовых образов c префиксом
`alt`. В состав базовых входят образы:

\- `alt/alt:платформа`

\- `alt/distroless-base:платформа`

Где `платформа` - `c10f2`, `p10`, `p11`, `sisyphus`, \...

Для их загрузки необходимо экспортировать переменную `U7S_PLATFORM`:

    export U7S_PLATFORM=alt

Команда разворачиваняи архива, подписи образов и размещения их на
регистраторе `registry.local` выглядит следующим образом:

    U7S_PLATFORM=alt podsec-load-sign-oci <xz-архив-базовых-образов> <архитектура>  <e-mail-подписывающего>

После размещения образы доступны под именами:

\- `registry.local/alt/alt:платформа`

\- `registry.local/alt/distroless-base:платформа`

###### Загрузка создаваемых или сторонних образов {#загрузка_создаваемых_или_сторонних_образов}

Образ в домене `registry.local/``</prefix>`{=html}`/` может быть
получен:

- присваивании алиаса стороннему образу:

<!-- -->

    podman tag <сторонний_образ> registry.local/</prefix>/<локальный_образ>

- сборки образов через `Dockerfile`.

<!-- -->

    podman build -t registry.local/</prefix>/<локальный_образ> ...

Для этих образов пользователь группу `podsec-dev` должен создать образ в
домене локального регистратора `registry.local/``</prefix>`{=html}`/` и
поместить его в регистратор командой:

    podman push --tls-verify=false --sign-by="<email-подписанта" <образ>

## Указание платформы {#указание_платформы}

Кроме имени регистратора kubernetes-образы altlinux содержит в имени
(например registry.altlinux.org/k8s-p10/kube-apiserver) название
платформы:

- k8s-p10 - образы для дистрибутива p10;
- k8s-c10f2 - образы сертифицированного дистрибутива c10f;
- test_k8s - тестовые образы;
- \...

Платформу устанавливаемых образов можно указать в переменной
`U7S_PLATFORM`. Например:

    export U7S_PLATFORM=test_k8s

## Автоматический выбор регистратора образов и платформы {#автоматический_выбор_регистратора_образов_и_платформы}

Если переменная `U7S_REGISTRY` не установлена, ее значения вычисляется
автоматически по следующему алгоритму:

- Если файл `/etc/hosts` содержит описание хоста `registry.local`
  префикс переменной `U7S_REGISTRY` принимает значение
  `registry.local/`, иначе `registry.altlinux.org/`.
- Если переменная `CPE_NAME` файла `/etc/os-release` содержит значение
  `spserver` суффикс переменной `U7S_PLATFORM` принимает значение
  `k8s-c10f2`, иначе `k8s-p10`.

# Добавление новых образов в локальный регистратор registry.local на платформах c10f {#добавление_новых_образов_в_локальный_регистратор_registry.local_на_платформах_c10f}

`rootless-kubernetes`, разворачиваемый на платформах `c10f` должен
обеспечивать работу при отсутствии доступа в Интернет. В этом случае в
рамках kubernetes-кластера поднимается локальный регистратор
`registry.local`. На всех узлах кластера в файле `/etc/hosts`
производится привязка имени `registry.local` к IP-адресу основного
master-сервера kubernetes. Кроме этого на master-сервере поднимается
WEB-сервер под именем `sigstore.local` для доступа к открытым GPG-ключам
пользователей, помещающих подписанные образы в регистратор
`registry.local`.

## Пользователи группы podman_dev {#пользователи_группы_podman_dev}

Добавление и корректировка `docker-образов` производится пользователями
принадлежащей группе `podman_dev`. При разворачивании кластера эти
пользователи создаются скриптом `podsec-create-imagemakeruser`.
Стандартно по документации создается один пользователь с именем
`imagemaker`. В дальнейшем мы будем использовать это имя.

При создании пользователя создаются открытый и закрытый `GPG-ключи` для
подписывания помещаемых в `registry.local` образов. Открытый ключ
помещается в каталог `/var/sigstore/keys/` по именем `imagemaker.pgp`.
Данный файл доступен с любого узла кластера по http-протоколу по адресу
[`http://sigstore.local:81/keys/imagemaker.pgp`](http://sigstore.local:81/keys/imagemaker.pgp).

## Структура каталогов и файлов политик доступа к регистраторам для обычных пользователей {#структура_каталогов_и_файлов_политик_доступа_к_регистраторам_для_обычных_пользователей}

Кроме этого в каталоге `/var/sigstore/keys/` master-сервера находится
файл `policy.json`, являющийся копией файла политик доступа к
регистраторам `/etc/containers/policy.json`. Данный файл доступен с
любого узла кластера по http-протоколу по адресу
[`http://sigstore.local:81/keys/policy.json`](http://sigstore.local:81/keys/policy.json).
Это файл используется для формирования файлов
`/etc/containers/policy.json` на разворачиваемых узлов кластера.

Файл `policy.json` имеет следующее содержание:

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

Это файл запрещает любой доступ к регистаторам, кроме регистратора
`registry.local`. При этом образы на данном регистраторе должны быть
подписаны пользователем имеющим открытый ключ, хранящийся в файле
`/var/sigstore/keys/imagemaker.pgp`.

В каталог `/var/sigstore/sigstore/` помещаются электронные подписи всех
образов, хранящихся в регистраторе `registry.local`.

    /var/sigstore/sigstore/
    └── k8s-c10f2
        ├── coredns@sha256=8199b34e550b94f6f2fb0d5539e3d1ac861db3b3cabdde85d72019d26f631e80
        │   └── signature-1
        ...

Кроме этого в файле `/etc/containers/registries.d/default.yaml`
описываются методы доступа к электронным подписям образов, Он имеет
следующее содержание:

    default-docker:
      lookaside: http://sigstore.local:81/sigstore/
      sigstore: http://sigstore.local:81/sigstore/

URL
[`http://sigstore.local:81/sigstore/`](http://sigstore.local:81/sigstore/)
указывает а каталог `/var/sigstore/sigstore/` на master-сервере и
используется для доступа к электронным подписям образов. Данные подписи
при загрузке образов проверяются на соответствие открытому ключу,
хранящемуся в файле `/var/sigstore/keys/imagemaker.pgp`. В случае их
соответствия образ загружается.

## Структура каталогов и файлов политик доступа к регистраторам пользователей группы podman_dev (imagemaker) {#структура_каталогов_и_файлов_политик_доступа_к_регистраторам_пользователей_группы_podman_dev_imagemaker}

Пользователи группы `podman_dev` в домашнем каталоге содержит файлы: -
`~/.config/containers/policy.json` -
`~/.config/containers/registries.d/default.yaml`.

Эти файлы перекрывают содержимое системных файлов
`/etc/containers/policy.json`,
`/etc/containers/registries.d/default.yaml`.

Файл `~/.config/containers/policy.json` имеет следующее содержание:

    {
      "default": [
        {
          "type": "insecureAcceptAnything"
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

`default.type=insecureAcceptAnything` определяет, что данный
пользователь может работать с образами любых регистраторов.

Файл `/etc/containers/registries.d/default.yaml` имеет следующее
содержание:

    default-docker:
      lookaside: http://sigstore.local:81/sigstore/
      sigstore: http://sigstore.local:81/sigstore/
      lookaside-staging: file:///var/sigstore/sigstore/
      sigstore-staging: file:///var/sigstore/sigstore/

Описатели `lookaside-staging`, `lookaside-staging` указывают каталог в
который записываются электронные подписи образов.

## Добавление новых образов в локальный регистратор registry.local {#добавление_новых_образов_в_локальный_регистратор_registry.local}

Добавление новых образов в локальный регистратор может осуществляться
только пользователями входящими в группу `podman_dev`

В регистратор могут помещаться два типа образов:

- копии сторонних образов;
- образы, собранные пользователем из группы `podman_dev` командой
  `podman build` или аналогичными.

### Получении образов с префиксом локального регистратора {#получении_образов_с_префиксом_локального_регистратора}

Все перечисленные образы для размещения в локальном региcтраторе
`registry.local` должные иметь в имени префикс совпадающий с именем
регистратора.

Загрузку и добавление нового алиаса к стороннему образу можно
осуществить с помощью команд:

    podman pull <имя_образа>:<тег>
    podman tag <имя_образа>:<тег> registry.local.<имя_образа_без_префикса>:<тег>

Аналогичного результата можно добиться путем создания в отдельном пустом
каталоге файла `Dockerfile`:

    FROM <имя_образа>:<тег>

и создание образа командой:

    podman build -t registry.local/<имя_образа_без_префикса>:<тег> .

При построении собственных образов необходимо создать в отдельном
каталоге файл `Dockerfile`:

    FROM <имя_образа>:<тег>
    ...

и построить на основе этого файла собственный образ указав в имени
собираемого образа префикс `registry.local`:

    podman build -f <путь_до_Dockerfile> -t registry.local/<имя_образа_без_префикса>:<тег> <каталог_данных_для_образа>

### Подписывание образов и их размещение в локальном регистраторе {#подписывание_образов_и_их_размещение_в_локальном_регистраторе}

Данная операция выполняется одной командой:

    podman push --tls-verify=false --sign-by="<E-mail_подписанта>" registry.local/<имя_образа_без_префикса>:<тег>

## Пример размещения в локальном регистраторе внешнего образа {#пример_размещения_в_локальном_регистраторе_внешнего_образа}

Зайдем на узел под пользователем `imagemaker`. Загрузим образ
`docker.io/library/nginx:1.26.2`:

    [imagemaker@host-70 ~]$ podman pull docker.io/library/nginx:1.26.2
    Trying to pull docker.io/library/nginx:1.26.2...
    Getting image source signatures
    Copying blob 692a61bd1d67 done   |
    Copying blob a480a496ba95 done   |
    Copying blob f7e45c747637 done   |
    Copying blob eec32f85414d done   |
    Copying blob 8992a25329a6 done   |
    Copying blob f8eff2f530ec done   |
    Copying blob 7a37000823d1 done   |
    Copying config 122ce9f0cb done   |
    Writing manifest to image destination
    122ce9f0cbb4dfe43ffdb473f28715920b333fdb1a24276feb9164a36dc9e817

Проверим наличие образа в списке образов пользователя `imagemaker`:

    [imagemaker@host-70 ~]$ podman images
    REPOSITORY                                        TAG              IMAGE ID      CREATED       SIZE
    ...
    docker.io/library/nginx                           1.26.2           122ce9f0cbb4  2 months ago  192 MB

Присвоим образу `docker.io/library/nginx:1.26.2` альтернативное имя
`registry.local/library/nginx:1.26.2` с префиксом `registry.local`:

    [imagemaker@host-70 ~]$ podman tag docker.io/library/nginx:1.26.2 registry.local/library/nginx:1.26.2

Проверим наличие альтернативного имени:

    [imagemaker@host-70 ~]$ podman images
    REPOSITORY                                        TAG              IMAGE ID      CREATED       SIZE
    ...
    registry.local/library/nginx                      1.26.2           122ce9f0cbb4  2 months ago  192 MB
    docker.io/library/nginx                           1.26.2           122ce9f0cbb4  2 months ago  192 MB

Обратите внимание, что оба образа имеют одинаковый
`IMAGE ID`:`122ce9f0cbb4`.

Подпишем образ закрытым ключом с идентификатором `kaf@basealt.ru` и
поместим его на регистратор `registry.local`:

    [imagemaker@host-70 ~]$ podman push --tls-verify=false --sign-by='kaf@basealt.ru' registry.local/library/nginx:1.26.2
    Getting image source signatures
    Copying blob 6895d9cc0852 done   |
    Copying blob 98b5f35ea9d3 done   |
    Copying blob 13de84ad01b1 done   |
    Copying blob c3f432d8d95a done   |
    Copying blob be367852680a done   |
    Copying blob f0a47df3ae96 done   |
    Copying blob 244255f1ea0b done   |
    Copying config 122ce9f0cb done   |
    Writing manifest to image destination
    Creating signature: Signing image using simple signing

Проверим наличие образа с именем `library/nginx` на регистраторе
`registry.local`:

    [imagemaker@host-70 ~]$ curl -s http://registry.local/v2/_catalog | jq
    {
      "repositories": [
        ...
        "library/nginx"
      ]
    }

Проверим наличие тега `1.26.2` у образа:

    [imagemaker@host-70 ~]$ curl -s  http://registry.local/v2/library/nginx/tags/list | jq
    {
      "name": "library/nginx",
      "tags": [
        "1.26.2"
      ]
    }

Проверим наличие подписи (файла `signature-1`) в каталоге
`/var/sigstore/sigstore/library/nginx@sha256=...`:

    [imagemaker@host-70 ~]$ ls -lR /var/sigstore/sigstore/library/
    /var/sigstore/sigstore/library/:
    итого 4
    drwxr-xr-x 2 imagemaker podman 4096 окт 30 17:37 'nginx@sha256=35705f3156d9dc894f5c69e3a60d018a05785d57ad13b966986043c6cef4e394'

    '/var/sigstore/sigstore/library/nginx@sha256=35705f3156d9dc894f5c69e3a60d018a05785d57ad13b966986043c6cef4e394':
    итого 4
    -rw-r--r-- 1 imagemaker podman 595 окт 30 17:37 signature-1

Создадим манифесты `Deployment` и `Service` для образа
`registry.local/library/nginx:1.26.2` в `namespace` `nginx-ns` в файле
`nginx.yaml`:

    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: nginx-deployment
      namespace: nginx-ns
    spec:
      selector:
        matchLabels:
          app: nginx
      replicas: 2
      template:
        metadata:
          labels:
            app: nginx
        spec:
          containers:
          - name: nginx
            image: registry.local/library/nginx:1.26.2
            ports:
            - containerPort: 80
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: nginx
      labels:
        app: nginx
      namespace: nginx-ns
    spec:
      type: NodePort
      ports:
      - port: 80
        targetPort: 80
      selector:
        app: nginx

Создадим `namespace` `nginx-ns` и применим созданные в файле
`nginx.yaml` манифесты:

    [root@host-70 ~]# kubectl create ns nginx-ns
    namespace/nginx-ns created
    [root@host-70 ~]# kubectl  apply -f nginx.yaml
    deployment.apps/nginx-deployment created
    service/nginx created

Дождемся состояния `1/1` для `POD`ов `nginx-deployment-...`:

    [root@host-70 ~]# kubectl  get all -n nginx-ns
    NAME                                    READY   STATUS    RESTARTS   AGE
    pod/nginx-deployment-5d54559f98-ffv49   1/1     Running   0          19s
    pod/nginx-deployment-5d54559f98-nxlkm   1/1     Running   0          19s

    NAME            TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
    service/nginx   NodePort   10.103.32.218   <none>        80:32338/TCP   19s

    NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
    deployment.apps/nginx-deployment   2/2     2            2           19s

    NAME                                          DESIRED   CURRENT   READY   AGE
    replicaset.apps/nginx-deployment-5d54559f98   2         2         2       19s

Если у Вас поднят единственный master-узел не забудьте предвариательно
снять ограничение на запуск обычных `POD`ов на master-узле:

    kubectl taint nodes <host>  node-role.kubernetes.io/control-plane:NoSchedule-

# podsec-k8s-rbac - Поддержка управление доступом на основе ролей (RBAC) {#podsec_k8s_rbac___поддержка_управление_доступом_на_основе_ролей_rbac}

В пакет `podsec-k8s-rbac` входит набор скриптов для работы с `RBAC` -
`Role Based Access Control`:

- `podsec-k8s-rbac-create-user` - создание `RBAC-пользователя`;
- `podsec-k8s-rbac-create-kubeconfig` - создание ключей, сертификатов и
  файла конфигурации `RBAC-пользователя`;
- `podsec-k8s-rbac-create-remoteplace` - создание удаленного рабочего
  места;
- `podsec-k8s-rbac-bindrole` - привязывание пользователя к кластерной
  или обычной роли;
- `podsec-k8s-rbac-get-userroles` - получить список кластерные и обычных
  ролей пользователя;
- `podsec-k8s-rbac-unbindrole` - отвязывание пользователя от кластерной
  или обычной роли.

## podsec-k8s-rbac-create-user - создание RBAC-пользователя {#podsec_k8s_rbac_create_user___создание_rbac_пользователя}

**Формат**:

    podsec-k8s-rbac-create-user имя_пользователя

**Описание**:

Скрипт:

- создает RBAC пользователя
- создает в домашнем директории каталог .kube
- устанавливаются соответствующие права доступа к каталогам.

## podsec-k8s-rbac-create-kubeconfig - создание ключей, сертификатов и файла конфигурации RBAC-пользователя {#podsec_k8s_rbac_create_kubeconfig___создание_ключей_сертификатов_и_файла_конфигурации_rbac_пользователя}

**Формат**:

    podsec-k8s-rbac-create-kubeconfig имя_пользователя[@<имя_удаленного_пользователя>] [группа ...]

**Описание**: Скрипт должен вызываться администратором безопасности
средства контейнеризации.

Для `rootless` решения имя удаленного пользователя принимается
`u7s-admin`.

Для `rootfull` решения необходимо после символа `@` указать
`имя удаленного пользователя`.

Скрипт в каталоге `~имя_пользователя/.kube производит`:

- Создании личного (private) ключа пользователя (файл
  `имя_пользователя.key`).
- Создание запроса на подпись сертификата (CSR) (файл
  `имя_пользователя.key`).
- Запись `запроса на подпись сертификата CSR`в кластер.
- Подтверждение `запроса на подпись сертификата (CSR)`.
- Создание `сертификата` (файл `имя_пользователя.crt`).
- Проверку корректности сертификата
- Формирование файла конфигурации пользователя (файл `config`)
- Добавление контекста созданного пользователя

## podsec-k8s-rbac-create-remoteplace - создание удаленного рабочего места {#podsec_k8s_rbac_create_remoteplace___создание_удаленного_рабочего_места}

**Формат**:

    podsec-k8s-rbac-create-remoteplace ip-адрес

**Описание**:

Скрипт производит настройку удаленного рабочего места пользователя путем
копирования его конфигурационного файла.

## podsec-k8s-rbac-bindrole - привязывание пользователя к кластерной или обычной роли {#podsec_k8s_rbac_bindrole___привязывание_пользователя_к_кластерной_или_обычной_роли}

**Формат**:

    podsec-k8s-rbac-bindrole имя_пользователя role|role=clusterrole|clusterrole роль имя_связки_роли [namespace]

**Описание**:

Скрипт производит привязку пользователя к обычной или кластерной роли
используя имя_связки_роли.

**Параметры**:

- имя_пользователя должно быть создано командой
  podsec-k8s-rbac-create-user и сконфигурировано на доступ к кластеру
  командой podsec-k8s-rbac-create-kubeconfig;
- тип роли может принимать следующие значения:

`   * role - пользователь привязывется к обычной роли с именем ``<роль>`{=html}` (параметр namespace в этом случае обязателен);`\
`   * role=clusterrole - пользователь привязывется к обычной роли используя кластерную роль с именем ``<роль>`{=html}` (параметр namespace в этом случае обязателен);`\
`   * clusterrole - пользователь привязывется к кластерной роли используя кластерную роль с именем ``<роль>`{=html}` (параметр namespace в этом случае должен отсутствовать).`

- роль - имя обычной или кластерной роли в зависимости от предыдущего
  параметра;
- имя_связки_роли - имя объекта класса rolebindings или
  clusterrolebindings в зависимости от параметра тип роли. В рамках
  этого объекта к кластерной или обычной роли могут быть привязаны
  несколько пользователей.
- namespace - имя namespace для обычной роли.

## podsec-k8s-rbac-get-userroles - получить список кластерные и обычных ролей пользователя {#podsec_k8s_rbac_get_userroles___получить_список_кластерные_и_обычных_ролей_пользователя}

**Формат**:

    podsec-k8s-rbac-get-userroles имя_пользователя [showRules]

**Описание**:

Скрипт формирует список кластерные и обычных ролей которые связаны с
пользователем. При указании флага `showRules`, для каждой роли
указывается список правил (\"`rules:[...]`\"), которые принадлежат
каждой роли пользователя.

Результат возвращается в виде `json-строки` формата:

    {
      "": {
        "clusterRoles": [...],
        "roles": {
          "allNamespaces": [...],
          "namespaces": [
            {
              "": [...],
              ...
            }
        }
      }
    }

Где `[...]` - массив объектов типа:

    {
      "bindRoleName": "",
      "bindedRoleType": "ClusterRole|Role",
      "bindedRoleName": "",
      "unbindCmd": "podsec-k8s-rbac-unbindrole ..."
    }

## podsec-k8s-rbac-unbindrole - отвязывание пользователя от кластерной или обычной роли {#podsec_k8s_rbac_unbindrole___отвязывание_пользователя_от_кластерной_или_обычной_роли}

**Формат**:

    podsec-k8s-rbac-unbindrole имя_пользователя role|clusterrole роль имя_связки_роли [namespace]

**Описание**:

Скрипт производит отвязку роли от кластерной или обычной роли, созданной
командой `podsec-k8s-rbac-bindrole`. Полный текст команды можно получить
в выводе команды `podsec-k8s-rbac-get-userroles` в поле `unbindCmd`.
Если в указанном имя_связки_роли объекте класса `rolebindings` или
`clusterrolebindings` еще остаются пользователи - объект модифицируется.
Если список становится пуст - объект удаляется.

**Параметры**:

- `имя_пользователя` должно быть создано командой
  `podsec-k8s-rbac-create-user` и сконфигурировано на доступ к кластеру
  командой `podsec-k8s-rbac-create-kubeconfig`;
- тип роли может принимать следующие значения:

`   * ``role`` - пользователь привязывается к обычной роли с именем ``<роль>`{=html}` (параметр ``namespace`` в этом случае обязателен);`\
`   * ``clusterrole`` - пользователь привязывается к кластерной роли используя кластерную роль с именем ``<роль>`{=html}` (параметр ``namespace`` в этом случае должен отсутствовать).`

- `роль` - имя обычной или кластерной роли в зависимости от предыдущего
  параметра;
- `имя_связки_роли` - имя объекта класса `rolebindings` или
  `clusterrolebindings` в зависимости от параметра тип роли. В рамках
  этого объекта к кластерной или обычной роли могут быть привязаны
  несколько пользователей.
- `namespace` - имя `namespace` для обычной роли.

# podsec-inotify - Мониторинг безопасности системы {#podsec_inotify___мониторинг_безопасности_системы}

В пакет podsec-inotify входит набор скриптов для мониторинга
безопасности системы:

- podsec-inotify-check-policy - проверка настроек политики
  контейнеризации на узле;
- podsec-inotify-check-containers - проверка наличия изменений файлов в
  директориях rootless контейнерах;
- podsec-inotify-check-images - проверка образов на предмет их
  соответствия настройки политикам контейнеризации на узле;
- podsec-inotify-check-kubeapi - мониторинг аудита API-интерфейса
  kube-apiserver control-plane узла;
- podsec-inotify-check-vuln - мониторинг docker-образов узла сканером
  безопасности trivy.

## Настройка сервиса trivy {#настройка_сервиса_trivy}

Часть скриптов мониторинга для обнаружения уязвимостей использует сканер
trivy.

Сканер безопасности trivy работает как клиент сервера trivy принимающего
соединения по порту 4954 на узле с доменом `trivy.local`. Если Ваш узел
работает в составе кластера, то необходимо:

- на одном из узлов кластера поднять сервер trivy командой:

<!-- -->

    systemctl enable --now trivy

- на всех узлах кластера прописать в файле `/etc/hosts` строку

<!-- -->

    <IP-адрес_узла_сервера_trivy> trivy.local

Если Ваш узел вне кластера необходимо:

- на узле поднять сервер trivy командой:

<!-- -->

    systemctl enable --now trivy

- прописать в файле `/etc/hosts` строку

<!-- -->

    127.0.0.1 trivy.local

*На платформе `c10f` сервер `trivy` запускается автоматически скриптом
`podsec-create-services` на мастер-сервере кластера, привязка домена
`trivy.local` к IP-адресу сервера производится автоматически скриптом
`podsec-create-policy`.*

## Мониторинг сообщений об уязвимостей через nagwad {#мониторинг_сообщений_об_уязвимостей_через_nagwad}

Все сообщения об обнаруженных уязвимостях скрипты записывают в системный
лог в следующем формате:

    <месяц> <день> <время> <host> <имя_скрипта>[<id>]: <уровень_уязвимости>: <текст_сообщения>

Посмотреть эти сообщения можно командой:

    journalctl  -t <имя_скрипта>

Например:

    journalctl  -t podsec-inotify-check-vuln

    июл 16 06:22:36 host-136 podsec-inotify-check-vuln[383501]: Critical: В образе registry.altlinux.org/k8s-sisyphus/kube-apiserver:v1.30.1 пользователя u7s-admin обнаружены критические и высокие уязвимости.
    ...

Для передачи сообщений серверу мониторинга общей инфраструктуры `icigna`
необходимо поднять сервис `nagwad`:

    # apt-get install nagwad-service
    # systemctl enable --now nagwad

В файловой системе создастся каталог
`/var/log/nagwad/``<boot_uid>`{=html}`/podsec/`. Все сообщения об
уязвимостях сервис `nagwad` будет записывать из системного лога в данный
каталог в файлы под именем
`podsec.``<message_id>`{=html}`.``<level>`{=html}.

Например `/var/log/nagwad/3c22e4b3-d4d7-4975-a49c-f630a15c041d/podsec/`:

    CRITICAL: podsec-inotify-check-vuln(Critical) В образе registry.altlinux.org/k8s-sisyphus/kube-apiserver:v1.30.1 пользователя u7s-admin обнаружены критические и высокие уязвимости.

Эти файлы в дальнейшем передаются серверу мониторинга общей
инфраструктуры `icigna`.

## podsec-inotify-check-policy - проверка настроек политики контейнеризации на узле {#podsec_inotify_check_policy___проверка_настроек_политики_контейнеризации_на_узле}

**Формат**:

    podsec-inotify-check-policy [-v[vv]] [-a интервал] [-f интервал] -c интервал -h интервал [-m  интервал] х-w интервалъ [-l интервал] [-d интервал]

**Описание**: Плугин проверяет настройки политики контейнеризации на
узле.

Проверка идет по следующим параметрам:

- файл `policy.json` установки транспортов и политик доступа к
  регистраторам:

  Параметр контроля пользователей                                                                                             Вес метрики
  --------------------------------------------------------------------------------------------------------------------------- -------------
  имеющих `defaultPolicy != reject`, но не входящих в группу `podman_dev`                                                     102
  не имеющих не имеющих `registry.local` в списке регистраторов для которых проверяется наличие электронной подписи образов   103
  имеющих в политике регистраторы для которых не проверяется наличие электронной подписи образов                              104
  имеющих в списке поддерживаемых транспорты отличные от `docker` (транспорт получения образов с регистратора)                105

- файлы привязки регистраторов к серверам хранящим электронные подписи
  (файл привязки о умолчанию `default.yaml` и файлы привязки
  регистраторов `*.yaml` каталога `registries.d`). Наличие (число)
  пользователей:

  Параметр контроля пользователей                                                                                                                     Вес метрики
  --------------------------------------------------------------------------------------------------------------------------------------------------- -------------
  не использующих хранилище подписей [`http://sigstore.local:81/sigstore/`](http://sigstore.local:81/sigstore/) как хранилище подписей по умолчанию   106

- контроль групп пользователей

1.  наличие пользователей имеющих образы, но не входящих в группу
    `podman`:

  Параметр контроля пользователей                                          Вес метрики
  ------------------------------------------------------------------------ -------------
  наличие пользователей имеющих образы, но не входящих в группу `podman`   101

1.  наличие пользователей группы `podman` (за исключением входящих в
    группу `podman_dev`):

  Параметр контроля пользователей                                        Вес метрики
  ---------------------------------------------------------------------- --------------------------
  входящих в группу `wheel`                                              101
  имеющих каталог `.config/containers/` открытым на запись и изменения   90 \* `доля_нарушителей`
  не имеющих файла конфигурации `.config/containers/storage.conf`        90 \* `доля_нарушителей`

`доля_нарушителей` считается как:
`число_нарушителей / число_пользователей_группы_podman`

Все веса метрик суммируются и формируется итоговая метрика.

## podsec-inotify-check-containers - проверка наличия изменений файлов в директориях rootless контейнерах {#podsec_inotify_check_containers___проверка_наличия_изменений_файлов_в_директориях_rootless_контейнерах}

**Формат**:

    podsec-inotify-check-containers

**Описание**:

Скрипт:

- создаёт список директорий `rootless` контейнеров, существующих в
  системе,
- запускает проверку на добавление,удаление, и изменение файлов в
  директориях контейнеров,
- отсылает уведомление об изменении в системный лог.

## podsec-inotify-check-images - проверка образов на предмет их соответствия настройки политикам контейнеризации на узле {#podsec_inotify_check_images___проверка_образов_на_предмет_их_соответствия_настройки_политикам_контейнеризации_на_узле}

**Формат**:

    podsec-inotify-check-images [-v[vv]] [-a интервал] [-f интервал] -c интервал -h интервал [-m  интервал] х-w интервалъ [-l интервал] [-d интервал]

**Описание**:

Плугин проверяет образы на предмет их соответствия настройки политикам
контейнеризации на узле. Проверка идет по следующим параметрам:

  Параметр контроля пользователей                                                       Вес метрики
  ------------------------------------------------------------------------------------- -------------
  наличие в политике пользователя регистраторов не поддерживающие электронную подпись   101
  наличие в кэше образов неподписанных образов                                          101
  наличие в кэше образов вне поддерживаемых политик                                     101

Все веса метрик суммируются и формируется итоговая метрика.

## podsec-inotify-check-kubeapi - мониторинг аудита API-интерфейса kube-apiserver control-plane узла {#podsec_inotify_check_kubeapi___мониторинг_аудита_api_интерфейса_kube_apiserver_control_plane_узла}

**Формат**:

    podsec-inotify-check-kubeapi [-d]

**Описание**: Скрипт производит мониторинг файла
`/etc/kubernetes/audit/audit.log` аудита API-интерфейса
`kube-apiserver`.

Политика аудита располагается в файле
`/etc/kubernetes/audit/policy.yaml`:

    apiVersion: audit.k8s.io/v1
    kind: Policy
    omitManagedFields: true
    rules:
    # do not log requests to the following
    - level: None
      nonResourceURLs:
      - "/healthz*"
      - "/logs"
      - "/metrics"
      - "/swagger*"
      - "/version"
      - "/readyz"
      - "/livez"

    - level: None
      users:
        - system:kube-scheduler
        - system:kube-proxy
        - system:apiserver
        - system:kube-controller-manager
        - system:serviceaccount:gatekeeper-system:gatekeeper-admin

    - level: None
      userGroups:
        - system:nodes
        - system:serviceaccounts
        - system:masters

    # limit level to Metadata so token is not included in the spec/status
    - level: Metadata
      omitStages:
      - RequestReceived
      resources:
      - group: authentication.k8s.io
        resources:
        - tokenreviews

    # extended audit of auth delegation
    - level: RequestResponse
      omitStages:
      - RequestReceived
      resources:
      - group: authorization.k8s.io
        resources:
        - subjectaccessreviews

    # log changes to pods at RequestResponse level
    - level: RequestResponse
      omitStages:
      - RequestReceived
      resources:
      - group: "" # core API group; add third-party API services and your API services if needed
        resources: ["pods"]
        verbs: ["create", "patch", "update", "delete"]

    # log everything else at Metadata level
    - level: Metadata
      omitStages:
      - RequestReceived

Текущие настройки производят логирование всех обращений \"несистемных\"
пользователей (в том числе анонимных) к ресурсам `kubernetes`.

Скрипт производит выборку всех обращений, в ответ на которые был
сформирован код более `400` - запрет доступа. Все эти факты записываются
в системный журнал и накапливаются в файле логов
`/var/lib/podsec/u7s/log/kubeapi/forbidden.log`, который периодически
передается через посту системному адмиристратору.

**Параметры**:

- `-d` - скирпт запускается в режиме демона, производящего онлайн
  мониторинг файла `/etc/kubernetes/audit/audit.log` и записывающего
  факты запросов с запретом доступа в системный журнал и файл логов
  `/var/lib/podsec/u7s/log/kubeapi/forbidden.log`.

<!-- -->

- при запуске без параметров скрипт посылает файл логов
  `/var/lib/podsec/u7s/log/kubeapi/forbidden.log` почтой системному
  администратору (пользователь `root`) и обнуляет файл логов.

В состав пакета кроме этого скрипта входят:

- файл описания сервиса
  `</code>`{=html}/lib/systemd/system/podsec-inotify-check-kubeapi.service`</code>`{=html}.
  Для его запуска екобходимо выполнить команды:

<!-- -->

      # systemctl enable  podsec-inotify-check-kubeapi.service
      # systemctl start  podsec-inotify-check-kubeapi.service
      

- файл для `</code>`{=html}cron`</code>`{=html}
  `</code>`{=html}/etc/podsec/crontabs/podsec-inotify-check-kubeapi`</code>`{=html}.
  Файл содержит единственную строку с описанием режима запуска скрипта
  `</code>`{=html}podsec-inotify-check-kubeapi`</code>`{=html} для
  передачи почты системному администратору.

` Скрипт запускается один раз в 10 минут.`\
` Во время установки пакета строка файла (в случае ее отсутствия) дописыватся в ``</code>`{=html}`crontab``</code>`{=html}`-файл ``</code>`{=html}`/var/spool/cron/root``</code>`{=html}` пользователя ``</code>`{=html}`root``</code>`{=html}`.`\
` Если необходимо изменить режим запуска скрипта или выключить его это можно сделать командой редактирования ``</code>`{=html}`crontab``</code>`{=html}`-файла:`\
` `

      #  crontab -e
      

## podsec-inotify-check-vuln - мониторинг docker-образов узла сканером безопасности trivy {#podsec_inotify_check_vuln___мониторинг_docker_образов_узла_сканером_безопасности_trivy}

**Формат**:

    podsec-inotify-check-vuln

**Описание**:

Скрипт производит мониторинг `docker-образов` узла сканером безопасности
`trivy`:

- Если скрипт запускается от имени пользователя `root` скрипт:

1.  проверяет сканером `trivy` `rootfull` образы;
2.  для всех пользователей каталога `/home/` проверяется наличие
    `rootless`-образов. При их наличии проверяет сканером `trivy` эти
    образы.

- Если скрипт запускается от имени обычного пользователя проверяется
  наличие `rootless`-образов. При их наличии проверяет сканером `trivy`
  эти образы.

Результат анализа посылается в системный лог. Если при анализе образа
число обнаруженных угроз уровня `HIGH` больше 0, результат посылается
почтой системному администратору (`root`).

**Параметры**:

Отсутствуют.

**Периодический запуск скрипта**

В состав пакета кроме этого входит systemd/timers файл
`/usr/lib/systemd/system/podsec-inotify-check-vuln.timer`.

При его активации командой:

    systemctl enable podsec-inotify-check-vuln.timer

каждый час запускается скрипт мониторинга.

Период запуска можно указать в описателе `OnCalendar` вышеуказанного
systemd/timers файла.

# Полезные советы, исправление проблем функционирования кластера {#полезные_советы_исправление_проблем_функционирования_кластера}

## Восстановление открытого ключа подписи образов {#восстановление_открытого_ключа_подписи_образов}

При порче или удалении файла открытого ключа
`/var/sigstore/keys/``<пользователь>`{=html}`.gpg` на master-узле его
можно восстановить по следующему алгоритму.

1\. Определите имя пользователя открытого ключа. Обычно это (по
документации) `imagemaker`.

2\. Выведите список ключей:

    # user=imagemaker
    # su - -c 'gpg2 --list-keys'  $user

Должно вывести что то типа:

    home/imagemaker/.gnupg/pubring.kbx
    -----------------------------------
    pub   rsa2048 2024-10-22 [SC]
          0DB75D48EB7704A78B8058896F36DD67EE906C77
    uid         [  абсолютно ] Alexey Kostarev <kaf@basealt.ru>
    sub   rsa2048 2024-10-22 [E]

Найдите строку uid. Скопируйта E-mail вместе со скобками и запишите в
переменную uid.

    # uid='<e-mail>'

3\. Сгенерируйте файл открытого ключа в каталоге `/var/sigstore/keys/`:

    su - -c "gpg2 --output /var/sigstore/keys/$user.pgp  --armor --export '$uid'" $user

4\. Если на других узлах также испорчены файлы открытых ключей
скопируйте их с master-узла:

    # user=imagemaker
    # curl http://sigstore.local/keys/${user}.gpg -o  /var/sigstore/keys/${user}.gpg
    # chmod 544 /var/sigstore/keys/${user}.gpg

## Указание версии flannel {#указание_версии_flannel}

При разворачивании узла кластера \`podsec\` устанавливает последнюю
версию \`flannel\`, доступную на регистраторе (например `v0.25.7`). Для
этой версии `podsec` выбирает deployment-файл, входящий в состав пакета
из каталога `/etc/podsec/u7s/manifests/kube-flannel/`. На текущий момент
каталог имеет следующую структуру:

    └── 0
        ├── 19
        │   ├── 0
        │   ├── 1
        │   └── 2
        ├── 20
        │   ├── 0
        │   ├── 1
        │   └── 2
        ├── 21
        │   ├── 0
        │   ├── 1
        │   ├── 2
        │   ├── 3
        │   ├── 4
        │   └── 5
        ├── 22
        │   ├── 0
        │   ├── 1
        │   ├── 2
        │   └── 3
        ├── 23
        │   └── 0
        ├── 24
        │   ├── 0
        │   ├── 1
        │   ├── 2
        │   ├── 3
        │   └── 4
        └── 25
            ├── 0
            ├── 1
            └── 7

Так как версии образа `flannel` постоянно обновляются может сложится
ситуация, когда нужный deployment-манифест в каталоге пакета не окажется
(как в нашем случая для версии `v0.25.7`). В этом случае необходимо
перед запуском `kubeadm init` указать последнюю существующую в каталоге
версию deployment-манифеста. В нашем случае:

    export U7S_FLANNEL_TAG=v0.25.1
