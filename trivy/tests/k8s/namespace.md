```
trivy k8s -n kube-system --report summary all
```
```
Summary Report for kubernetes-admin@kubernetes


Workload Assessment
┌─────────────┬──────────────────────────────────────────────┬───────────────────┬────────────────────┬───────────────────┐
│  Namespace  │                   Resource                   │  Vulnerabilities  │ Misconfigurations  │      Secrets      │
│             │                                              ├───┬───┬───┬───┬───┼───┬───┬───┬────┬───┼───┬───┬───┬───┬───┤
│             │                                              │ C │ H │ M │ L │ U │ C │ H │ M │ L  │ U │ C │ H │ M │ L │ U │
├─────────────┼──────────────────────────────────────────────┼───┼───┼───┼───┼───┼───┼───┼───┼────┼───┼───┼───┼───┼───┼───┤
│ kube-system │ Deployment/coredns                           │   │   │   │   │   │   │   │ 3 │ 5  │   │   │   │   │   │   │
│ kube-system │ Pod/etcd-host-144                            │   │   │   │   │   │   │ 1 │ 3 │ 7  │   │   │   │   │   │   │
│ kube-system │ Service/kube-dns                             │   │   │   │   │   │   │   │ 1 │    │   │   │   │   │   │   │
│ kube-system │ Pod/kube-apiserver-host-144                  │   │   │   │   │   │   │ 1 │ 3 │ 9  │   │   │   │   │   │   │
│ kube-system │ Pod/kube-controller-manager-host-144         │   │   │   │   │   │   │ 1 │ 3 │ 8  │   │   │   │   │   │   │
│ kube-system │ Pod/kube-scheduler-host-144                  │   │   │   │   │   │   │ 1 │ 3 │ 8  │   │   │   │   │   │   │
│ kube-system │ DaemonSet/kube-proxy                         │   │   │   │   │   │   │ 2 │ 4 │ 10 │   │   │   │   │   │   │
│ kube-system │ ConfigMap/extension-apiserver-authentication │   │   │   │   │   │   │ 1 │   │    │   │   │   │   │   │   │
└─────────────┴──────────────────────────────────────────────┴───┴───┴───┴───┴───┴───┴───┴───┴────┴───┴───┴───┴───┴───┴───┘
Severities: C=CRITICAL H=HIGH M=MEDIUM L=LOW U=UNKNOWN


RBAC Assessment
┌─────────────┬─────────────────────────────────────────────────────┬───────────────────┐
│  Namespace  │                      Resource                       │  RBAC Assessment  │
│             │                                                     ├───┬───┬───┬───┬───┤
│             │                                                     │ C │ H │ M │ L │ U │
├─────────────┼─────────────────────────────────────────────────────┼───┼───┼───┼───┼───┤
│ kube-system │ Role/system::leader-locking-kube-scheduler          │   │   │ 1 │   │   │
│ kube-system │ Role/system:controller:cloud-provider               │   │   │ 1 │   │   │
│ kube-system │ Role/system:controller:token-cleaner                │ 1 │   │   │   │   │
│ kube-system │ Role/system::leader-locking-kube-controller-manager │   │   │ 1 │   │   │
│ kube-system │ Role/system:controller:bootstrap-signer             │ 1 │   │   │   │   │
└─────────────┴─────────────────────────────────────────────────────┴───┴───┴───┴───┴───┘
Severities: C=CRITICAL H=HIGH M=MEDIUM L=LOW U=UNKNOWN


Infra Assessment
┌─────────────┬──────────────────────────────────────┬─────────────────────────────┐
│  Namespace  │               Resource               │ Kubernetes Infra Assessment │
│             │                                      ├─────┬─────┬─────┬─────┬─────┤
│             │                                      │  C  │  H  │  M  │  L  │  U  │
├─────────────┼──────────────────────────────────────┼─────┼─────┼─────┼─────┼─────┤
│ kube-system │ Pod/kube-apiserver-host-144          │     │     │ 1   │ 7   │     │
│ kube-system │ Pod/kube-controller-manager-host-144 │     │     │     │ 3   │     │
│ kube-system │ Pod/kube-scheduler-host-144          │     │     │     │ 1   │     │
└─────────────┴──────────────────────────────────────┴─────┴─────┴─────┴─────┴─────┘
Severities: C=CRITICAL H=HIGH M=MEDIUM L=LOW U=UNKNOWN
```