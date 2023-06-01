```
# trivy k8s --report summary cluster
```
<pre>
Summary Report for kubernetes-admin@kubernetes
==============================================

Workload Assessment
┌─────────────┬──────────────────────────────────────────────┬──────────────────────────┬────────────────────┬───────────────────┐
│  Namespace  │                   Resource                   │     Vulnerabilities      │ Misconfigurations  │      Secrets      │
│             │                                              ├────┬─────┬─────┬─────┬───┼───┬───┬───┬────┬───┼───┬───┬───┬───┬───┤
│             │                                              │ C  │  H  │  M  │  L  │ U │ C │ H │ M │ L  │ U │ C │ H │ M │ L │ U │
├─────────────┼──────────────────────────────────────────────┼────┼─────┼─────┼─────┼───┼───┼───┼───┼────┼───┼───┼───┼───┼───┼───┤
│ kube-system │ DaemonSet/kube-proxy                         │    │     │     │     │   │   │ 2 │ 4 │ 10 │   │   │   │   │   │   │
│ kube-system │ Pod/kube-controller-manager-host-144         │    │     │     │     │   │   │ 1 │ 3 │ 8  │   │   │   │   │   │   │
│ kube-system │ Pod/etcd-host-144                            │    │     │     │     │   │   │ 1 │ 3 │ 7  │   │   │   │   │   │   │
│ kube-system │ Service/kube-dns                             │    │     │     │     │   │   │   │ 1 │    │   │   │   │   │   │   │
│ kube-system │ Deployment/coredns                           │    │     │     │     │   │   │   │ 3 │ 5  │   │   │   │   │   │   │
│ kube-system │ ConfigMap/extension-apiserver-authentication │    │     │     │     │   │   │ 1 │   │    │   │   │   │   │   │   │
│ kube-system │ Pod/kube-scheduler-host-144                  │    │     │     │     │   │   │ 1 │ 3 │ 8  │   │   │   │   │   │   │
│ kube-system │ Pod/kube-apiserver-host-144                  │    │     │     │     │   │   │ 1 │ 3 │ 9  │   │   │   │   │   │   │
│ default     │ Deployment/nginx-deployment                  │ 57 │ 125 │ 116 │ 165 │ 7 │   │   │ 2 │ 11 │   │   │   │   │   │   │
│ default     │ ConfigMap/kube-root-ca.crt                   │    │     │     │     │   │   │   │   │ 1  │   │   │   │   │   │   │
│ default     │ Service/kubernetes                           │    │     │     │     │   │   │   │   │ 1  │   │   │   │   │   │   │
└─────────────┴──────────────────────────────────────────────┴────┴─────┴─────┴─────┴───┴───┴───┴───┴────┴───┴───┴───┴───┴───┴───┘
Severities: C=CRITICAL H=HIGH M=MEDIUM L=LOW U=UNKNOWN


RBAC Assessment
┌─────────────┬──────────────────────────────────────────────────────────────┬───────────────────┐
│  Namespace  │                           Resource                           │  RBAC Assessment  │
│             │                                                              ├───┬───┬───┬───┬───┤
│             │                                                              │ C │ H │ M │ L │ U │
├─────────────┼──────────────────────────────────────────────────────────────┼───┼───┼───┼───┼───┤
│ kube-system │ Role/system:controller:token-cleaner                         │ 1 │   │   │   │   │
│ kube-system │ Role/system:controller:cloud-provider                        │   │   │ 1 │   │   │
│ kube-system │ Role/system::leader-locking-kube-scheduler                   │   │   │ 1 │   │   │
│ kube-system │ Role/system::leader-locking-kube-controller-manager          │   │   │ 1 │   │   │
│ kube-system │ Role/system:controller:bootstrap-signer                      │ 1 │   │   │   │   │
│ kube-public │ Role/system:controller:bootstrap-signer                      │   │   │ 1 │   │   │
│ default     │ RoleBinding/adminofsmf                                       │   │   │   │ 1 │   │
│             │ ClusterRole/system:controller:generic-garbage-collector      │ 1 │   │   │   │   │
│             │ ClusterRole/admin                                            │ 3 │ 7 │ 1 │   │   │
│             │ ClusterRole/system:controller:replication-controller         │   │ 1 │   │   │   │
│             │ ClusterRole/system:controller:deployment-controller          │   │ 2 │   │   │   │
│             │ ClusterRole/system:controller:root-ca-cert-publisher         │   │   │ 1 │   │   │
│             │ ClusterRole/system:aggregate-to-admin                        │ 1 │   │   │   │   │
│             │ ClusterRole/system:controller:persistent-volume-binder       │ 1 │ 2 │   │   │   │
│             │ ClusterRole/system:controller:endpoint-controller            │   │ 1 │   │   │   │
│             │ ClusterRole/system:controller:job-controller                 │   │ 1 │   │   │   │
│             │ ClusterRole/cluster-admin                                    │ 2 │   │   │   │   │
│             │ ClusterRole/edit                                             │ 2 │ 7 │ 1 │   │   │
│             │ ClusterRole/system:controller:namespace-controller           │ 1 │   │   │   │   │
│             │ ClusterRole/system:controller:horizontal-pod-autoscaler      │ 2 │   │   │   │   │
│             │ ClusterRole/system:node                                      │ 1 │   │   │   │   │
│             │ ClusterRole/system:controller:endpointslice-controller       │   │ 1 │   │   │   │
│             │ ClusterRole/system:kube-controller-manager                   │ 5 │ 2 │   │   │   │
│             │ ClusterRole/system:kube-scheduler                            │   │ 2 │   │   │   │
│             │ ClusterRole/system:controller:endpointslicemirroring-contro- │   │ 1 │   │   │   │
│             │ ller                                                         │   │   │   │   │   │
│             │ ClusterRole/system:controller:resourcequota-controller       │ 1 │   │   │   │   │
│             │ ClusterRole/system:controller:expand-controller              │ 1 │   │   │   │   │
│             │ ClusterRole/system:controller:replicaset-controller          │   │ 1 │   │   │   │
│             │ ClusterRole/system:aggregate-to-edit                         │ 2 │ 7 │ 1 │   │   │
│             │ ClusterRole/system:controller:cronjob-controller             │   │ 2 │   │   │   │
└─────────────┴──────────────────────────────────────────────────────────────┴───┴───┴───┴───┴───┘
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


</pre>