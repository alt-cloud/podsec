# Настройка kubeadm для поддержки работы с rootless kubernetes (usernetes)

## Способы настройки:

* Замена service-файлов, обеспечивающих запуск user rootless-сервисов через системные сервисы
  - [kubelet](https://github.com/alt-cloud/podsec/blob/master/usernetes/services/kubelet.service)

*  Модификация кода kubelet


## Модификация кода kubeadm

- исключение загрузки ненужных для rootless-решения образов - нужны лишь coredns- и pause-образы
