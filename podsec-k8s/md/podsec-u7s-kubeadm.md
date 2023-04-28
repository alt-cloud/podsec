podsec-u7s-kubeadm(1) -- инициализация master- или worker-узла в rootless-kubernetes (alt usernetes)
================================

## SYNOPSIS

`podsec-u7s-kubeadm init| join <ApiServer>:6443 --token ... --discovery-token-ca-cert-hash ...`

## DESCRIPTION

Скрипт производит:


## EXAMPLES

`podsec-u7s-kubeadm init`
`podsec-u7s-kubeadm join 102.168.122.32:6443 --token ... --discovery-token-ca-cert-hash ...`

## SECURITY CONSIDERATIONS


- Так как все работа с кластером производится по REST-интерфейсу, то для обеспечения повышенных мер безопасности следует заводить **ВСЕХ пользователей**, включая *администратор безопасности средства контейнеризации* **ВНЕ узлов кластера**. Для работы с кластером достаточно команды `kubectl`, входящую в пакет `kubernetes-client`.

## SEE ALSO

- [Kubernetes](https://www.altlinux.org/Kubernetes);

- [Usernetes: Kubernetes without the root privileges](https://github.com/rootless-containers/usernetes);

- [Настроика аудита API-сервиса](https://github.com/alt-cloud/podsec/blob/master/k8s/RBAC/addUser/clusterroleBinding.md);

## AUTHOR

Костарев Алексей, Базальт СПО
kaf@basealt.ru
