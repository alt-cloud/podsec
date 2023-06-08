# Процедура обновления миновных версия kubernetes
```
$ kubectl edit cm kubeadm-config -n kube-system
```

<pre>
apiVersion: v1
data:
  ClusterConfiguration: |
...
    imageRepository: registry.altlinux.org/k8s-p10
...

</pre>
