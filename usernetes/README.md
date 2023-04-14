# Установка и настройка U7S (rootless kuber) по состоянию на 11.04.2023

1 Настройте репозиторий обновления
<pre>
apt-repo add 'rpm [p10] http://ftp.altlinux.org/pub/distributions/ALTLinux p10/branch/x86_64 classic'
apt-repo add 'rpm [p10] http://ftp.altlinux.org/pub/distributions/ALTLinux p10/branch/x86_64-i586 classic'
apt-repo add 'rpm [p10] http://ftp.altlinux.org/pub/distributions/ALTLinux p10/branch/noarch classic'
rm -f /etc/apt/sources.list.d/sources.list
apt-get update
</pre>

2 Установите podsec-пакеты:

  ```
  # apt-get install -y podsec-0.5.1-alt1.noarch.rpm      podsec-k8s-rbac-0.5.1-alt1.noarch.rpm podsec-k8s-0.5.1-alt1.noarch.rpm  podsec-nagios-plugins-0.5.1-alt1.noarch.rpm
  ```

3 Запустите команду:

  <pre>
  # podsec-u7s-create-node
  </pre>

Задайте пароль пользователю `u7s-admin`


5 После завершения скрипта проверьте работу `usernetes` (`rootless kuber`)

  <pre>
  # kubectl get nodes
  # kubectl get all -A
  </pre>

 Зайдите под пользователем `u7s-admin`

Проверьте работу `usernetes` (`rootless kuber`)

  <pre>
  # kubectl get all -A
  </pre>

5 Проверьте загрузку образа
<pre>
kubectl run -it --image=registry.local/alt/alt -- bash
</pre>



> Пока сервис не стартует после перезагрузки. Для запуска сервиса наберите:
<pre>
systemctl  start u7s
</pre>
