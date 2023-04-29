## Сравнение rootfull и rootless решения

## Сравнение троп и содержимого файлов конфигурации rootless и rootfull решения

### CONF файлы

Сервис         |Тропа rootfull (/etc/kubernetes/) | Тропа rootless (.config/usernetes/{master,node})
---------------|-----------------------------------|----------------
kube-scheduler |  scheduler.conf                    | kube-scheduler.kubeconfig
controller-manager | controller-manager.conf | kube-controller-manager.kubeconfig
kube-proxy     |             ?                | kube-proxy.kubeconfig
admin          |  admin.conf                       | admin-127.0.0.1.kubeconfig, admin-localhost.kubeconfig, node.kubeconfig


### Сертификаты(crt, pem)

Сервис         |  Тропа rootfull  (/etc/kubernetes/pki)| Тропа rootless (.config/usernetes/{master,node})
---------------|-----------------|----------------
apiserver | apiserver.crt |  ?
apiserver-etcd-client | apiserver-etcd-client.crt | ?
apiserver-kubelet-client | apiserver-kubelet-client.crt | ?
ca | ca.crt | ca.pem
front-proxy-ca | front-proxy-ca.crt | kube-proxy.pem
front-proxy-client | front-proxy-client.crt | ?
kube-controller-manager | ? | kube-controller-manager.pem
kubernetes | ? | kubernetes.pem
kube-scheduler | ? | kube-scheduler.pem
service-account | ? | service-account.pem
etcd/ca | etcd/ca.crt | ?
etcd/healthcheck-client | etcd/healthcheck-client.crt | ?
etcd/peer | etcd/peer.crt | ?
etcd/server.crt | etcd/server.crt | ?
node | ? | node.pem

### Ключи (.key, -key.pem)

Сервис         | Тропа rootfull | Тропа rootless
---------------|----------------|----------------
apiserver-etcd-client | apiserver-etcd-client.key | ?
apiserver | apiserver.key| ?
apiserver-kubelet-client | apiserver-kubelet-client.key| ?
ca | ca.key | ca-key.pem
etcd/ca| etcd/ca.key| ?
etcd/healthcheck-client| etcd/healthcheck-client.key| ?
etcd/peer| etcd/ca.key| ?
etcd/server| etcd/server.key| ?
front-proxy-ca| front-proxy-ca.key| kube-proxy-key.pem
front-proxy-client| front-proxy-client.key| ?
sa| sa.key| ?
admin-key | ? | admin-key.pem
kube-controller-manager-key| ? | kube-controller-manager-key.pem
kubernetes-key| ? | kubernetes-key.pem
kube-scheduler-key| ? | kube-scheduler-key.pem
service-account-key| ? | service-account-key.pem





### Манифесты 

Сервис         |  Тропа rootfull(/etc/kubernetes/manifests) | Тропа rootless (usernetes/manifests/)
---------------|-----------------|----------------
etcd | etcd.yaml | ?
kube-apiserver| kube-apiserver.yaml | ?
kube-controller-manager| kube-controller-manager.yaml | ?
kube-flannel| kube-flannel.yml | ?
kube-scheduler| kube-scheduler.yaml | ?
coredns | ? | coredns.yaml



## Сравнение параметров запуска сервисов rootfull и rootless решения

### etcd


Флаги rootfull | Флаги rootless 
---------------|----------------
--advertise-client-urls=https://10.150.0.161:2379 --cert-file=/etc/kubernetes/pki/etcd/server.crt --client-cert-auth=true --
data-dir=/var/lib/etcd --initial-advertise-peer-urls=https://10.150.0.161:2380 --initial-cluster=master01=https://10.150.0.161:2380 --key-file=/etc/kubernetes/pki/etcd/server.key --listen-client-urls=https://127.0.0.1:2379,https://10.150.0.161:2379 --listen-metrics-urls=http://127.0.0.1:2381 --listen-peer-urls=https://10.150.0.161:2380 --name=master01 --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt --peer-client-cert-auth=true --peer-key-file=/etc/kubernetes/pki/etcd/peer.key --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt --snapshot-count=10000 --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt |


### kube-apiserver

--advertise-address=10.150.0.161 --allow-privileged=true --authorization-mode=Node,RBAC --client-ca-file=/etc/kubernetes/pki/ca.crt --enable-admission-plugins=NodeRestriction --enable-bootstrap-token-auth=true --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key --etcd-servers=https://127.0.0.1:2379 --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname --proxy-client-cert-file=/etc/kubernetes/pki/front-proxy-client.crt --proxy-client-key-file=/etc/kubernetes/pki/front-proxy-client.key --requestheader-allowed-names=front-proxy-client --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt --requestheader-extra-headers-prefix=X-Remote-Extra- --requestheader-group-headers=X-Remote-Group --requestheader-username-headers=X-Remote-User --secure-port=6443 --service-account-issuer=https://kubernetes.default.svc.cluster.local --service-account-key-file=/etc/kubernetes/pki/sa.pub --service-account-signing-key-file=/etc/kubernetes/pki/sa.key --service-cluster-ip-range=10.96.0.0/12 --tls-cert-file=/etc/kubernetes/pki/apiserver.crt --tls-private-key-file=/etc/kubernetes/pki/apiserver.key
 

### kube-proxy

--config=/var/lib/kube-proxy/config.conf --hostname-override=master01

### flanneld

--ip-masq --kube-subnet-mgr

### kube-controller

--allocate-node-cidrs=true --authentication-kubeconfig=/etc/kubernetes/controller-manager.conf --authorization-kubeconfig=/etc/kubernetes/controller-manager.conf --bind-address=127.0.0.1 --client-ca-file=/etc/kubernetes/pki/ca.crt --cluster-cidr=10.244.0.0/16 --cluster-name=kubernetes --cluster-signing-cert-file=/etc/kubernetes/pki/ca.crt --cluster-signing-key-file=/etc/kubernetes/pki/ca.key --controllers=*,bootstrapsigner,tokencleaner --kubeconfig=/etc/kubernetes/controller-manager.conf --leader-elect=true --port=0 --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt --root-ca-file=/etc/kubernetes/pki/ca.crt --service-account-private-key-file=/etc/kubernetes/pki/sa.key --service-cluster-ip-range=10.96.0.0/12 --use-service-account-credentials=true

### -kube-scheduler

--authentication-kubeconfig=/etc/kubernetes/scheduler.conf --authorization-kubeconfig=/etc/kubernetes/scheduler.conf --bind-address=127.0.0.1 --kubeconfig=/etc/kubernetes/scheduler.conf --leader-elect=true --port=0

### kube-proxy

--logtostderr=true --v=0 --master=http://127.0.0.1:8080

### kubelet

--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --pod-manifest-path=/etc/kubernetes/manifests --network-plugin=cni --cni-conf-dir=/etc/cni/net.d --cni-bin-dir=/usr/libexec/cni --cluster-dns=10.96.0.10 --cluster-domain=cluster.local --authorization-mode=Webhook --client-ca-file=/etc/kubernetes/pki/ca.crt --cgroup-driver=systemd --container-runtime=remote --container-runtime-endpoint=unix:///var/run/crio/crio.sock

### 