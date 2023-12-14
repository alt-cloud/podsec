# Информация по команде kubeadm

## Поддерживаемые подкоманды

Подкоманда init | Подкоманда join | Поддержка
-------------------|-------------------|-------------
phase              | phase             |

## Поддерживаемые флаги

### Общесистемные флаги

init-флаг          | join-флаг     | Поддержка
-------------------|-------------------|-------------
-v:                | -v:               | **Y**
--add-dir-header:  | --add-dir-header: |
--log-file:         | --log-file:       |
--log-file-max-size:| --log-file-max-size: |
--one-output:       | --one-output:    |
--rootfs:           | --rootfs: |
--skip-headers    | --skip-headers
--skip-log-headers | --skip-log-headers

### kubeadm init | join

init-флаг          | join-флаг     | Поддержка
-------------------|-------------------|-------------
--apiserver-advertise-address: | --apiserver-advertise-address |
--apiserver-bind-port: | --apiserver-bind-port: |
--cert-dir: | **-** |
--certificate-key: | --certificate-key: |
--config: | --config: |
--control-plane-endpoint: | **-**  |
 **-** | --control-plane |
 --cri-socket: | --cri-socket: |
 **-**  | --discovery-file: |
 **-**  | --discovery-token: |
 **-**  | --discovery-token-ca-cert-hash: |
 **-**  | --discovery-token-unsafe-skip-ca-verification |
--dry-run | --dry-run |
--feature-gates: | **-**  |
--help: (-h:) | --help: (-h:) |
--ignore-preflight-errors: | --ignore-preflight-errors: |
--image-repository: | **-**  |
--kubernetes-version: | **-**  |
--node-name: | --node-name: |
--patches: | --patches: |
 --pod-network-cidr: | **-**  |
 --service-cidr: | **-**  |
 --service-dns-domain: | **-**  |
 --skip-certificate-key-print | **-**  |
 --skip-phases: | --skip-phases: |
 --skip-token-print | **-**  |
 **-**  | --tls-bootstrap-token: |
 --token: | --token: |
 --token-ttl: | **-**  |
 --upload-certs | **-**  |

### kubeadm upgrade

apply-флаг          | diff-флаг     | node-флаг | plan-флаг
--------------------|---------------|-------------|---------------
--allow-experimental-upgrades | **-** | **-** | --allow-experimental-upgrades 
--allow-release-candidate-upgrades | **-** | **-** | --allow-release-candidate-upgrades
**-** | --api-server-manifest: | **-** |  
**-** | --certificate-renewal | --certificate-renewal | 
**-** | -context-lines: (-c:) | **-** | 
**-** | --controller-manager-manifest: **-** | 
--etcd-upgrade | **-** | --etcd-upgrade |
**-** | **-** | **-** | --output (-o)
**-** | **-** | **-** | --print-config
**-** | **-** | **-** | --show-managed-fields
**-** | --scheduler-manifest: | **-** | 

### kubeadm reset

Flag |
-----|
--cleanup-tmp-dir |

