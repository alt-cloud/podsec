# Настройка kubeadm для поддержки работы с rootless kubernetes (usernetes)

## Способы настройки:

* Замена service-файлов, обеспечивающих запуск user rootless-сервисов через системные сервисы
  - [kubelet](https://github.com/alt-cloud/podsec/blob/master/usernetes/services/kubelet.service)
