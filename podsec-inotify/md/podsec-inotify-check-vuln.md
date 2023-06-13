podsec-inotify-check-vuln(1) -- скрипт мониторинга docker-образов узла сканером безопасности trivy
================================

## SYNOPSIS

`podsec-inotify-check-vuln` 

## DESCRIPTION

Для корректной работы скрипта необходимо запустить сервис `podsec-inotify-server-trivy`:
```
systemctl enable --now podsec-inotify-server-trivy
```

Скрипт производит мониторинг `docker-образов` узла сканером безопасности `trivy`.
Анализ производится для `rootfull`-образов пользователя `root` и `rootless`-образов пользователей, располагающихся в каталоге `/home`.

Если при анализе образа число обнаруженных угроз уровня `HIGH`  более 10-ти, результат анализа посылается в системный лог и посылается почтой системному администратору (`root`).


## OPTIONS

Отсутствуют.

В состав пакета кроме этого скрипта входит файл для `cron` `/etc/podsec/crontabs/podsec-inotify-check-vuln`. Файл содержит единственную строку с описанием режима запуска скрипта `podsec-inotify-check-vuln`.
Во время установки пакета строка файла (в случае ее отсутствия) дописыватся в `crontab`-файл `/var/spool/cron/root` пользователя `root`.
   
Если необходимо изменить режим запуска скрипта или выключить его это можно сделать командой редактирования `crontab`-файла:
<pre>
#  crontab -e
</pre>



## EXAMPLES

`podsec-inotify-check-vuln` 

## SECURITY CONSIDERATIONS

-

## SEE ALSO

[The all-in-one open source security scanner](https://trivy.dev/)


## AUTHOR

Костарев Алексей, Базальт СПО
kaf@basealt.ru
