# Установка и настройка U7S (rootless kuber) по состоянию на 11.04.2023

1 Установите podsec-пакеты:

  ```
  # apt-get install -y podsec-0.5.1-alt1.noarch.rpm      podsec-k8s-rbac-0.5.1-alt1.noarch.rpm podsec-k8s-0.5.1-alt1.noarch.rpm  podsec-nagios-plugins-0.5.1-alt1.noarch.rpm
  ```

2 Скачайте tar-архив `flannel_0.19.tgz`
  <pre>
  https://raw.githubusercontent.com/alt-cloud/podsec/master/usernetes/flannel_0.19.tgz
  </pre>

  Разархивируйте его в  корневой каталог:

  <pre>
  # tar xvzCf /  flannel_0.19.tgz
  </pre>

3 Запустите команду:

  <pre>
  # podsec-u7s-create-node
  </pre>

Задайте пароль пользователю `u7s-admin`


4 После завершения скрипта проверьте работу `usernetes` (`rootless kuber`)

  <pre>
  # kubectl get all -A
  </pre>

5 Зайдите под пользователем `u7s-admin`

Проверьте работу `usernetes` (`rootless kuber`)

  <pre>
  # kubectl get all -A
  </pre>
