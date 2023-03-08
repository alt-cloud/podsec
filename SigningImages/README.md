> Описанный здесь подход применим кроме "podman" и к решениям на базе 'kubernetes'
> В kubernetes-кластере необходимо:
>
> * при отсутствии DNS обеспечить добавление записей в /etc/hosts на ВСЕ узлы кластера:
> <pre>
> &lt;IP-адрес_компьютера_разработчика_образов&gt; sigstore.local
> &lt;IP-адрес_компьютера_разработчика_образов&gt; registry.local
> </pre>
>
> * если регистратор обеспечивает доступ ТОЛЬКО по незащищенному порту 80 (а не 443) добавит в файле /etc/crio/crio.conf на ВСЕХ узлах кластера:
> ```
> insecure_registries = [
>  "registry.local"
> ]
> ```
> Для версий `kubernetes < 1.26` необходимо в файле `/etc/containers/registries.d/default.yaml` кроме элемента `lookaside` указать элемент `sigstore` с тем же `URL`:
> ```
> default-docker:
>   lookaside: http://sigstore.local:81/sigstore/
>   sigstore: http://sigstore.local:81/sigstore/
> ```

# Разработчик образов контейнеров (imagemaker)

Пользователь входит в группы `podman`, `podman_dev`, `wheel`.
```console
# groupadd -r podman
# groupadd -r podman_dev
# adduser imagemaker -g podman -G podman_dev,wheel
# passwd imagemaker
# su -  imagemaker
$
```

## Включение возможности загрузки образов для разработчика образов контейнеров

Для поддержки всех типов транспорта создайте файл-конфигурации ~/.config/containers/policy.json:
```console
$ export EDITOR=/usr/bin/vim
$ mkdir -p export EDITOR=/bin/vim
$ $EDITOR ~/.config/containers/policy.json
```
```
{
  "default": [
    {
      "type": "insecureAcceptAnything"
    }
  ]
}
```


Создайте каталоги для хранения ключей и подписей образов:
```console
$ sudo mkdir -p -m 0775 /var/sigstore/keys/
$ sudo chown root:podman_dev /var/sigstore/keys/
$ sudo mkdir -m 0775 /var/sigstore/sigstore/
$ sudo chown root:podman_dev /var/sigstore/sigstore/
```
Запишите для `web-сервера sigstore` тестовую страницу:
```
$ sudo echo '<html><body><h1>It works!</h1></body></html>' > /var/sigstore/index.html
```

Примените один из способов запуска web-сервера, описанных ниже (рекомендуется запуск через `systemd`).

## Запуск web-сервера sigstore для хранения ключей и подписей образов

Выберите имя регистратора. Например: `sigstore.local` и при отсутсвии DNS-сервера добавьте его в `/etc/hosts`.
<pre>
&lt;IP-адрес_компьютера&gt; sigstore.local
</pre>
В качестве `<IP-адрес_компьютера>` необходимо указать адрес компьютера, который будет использоваться другими рабочими местами для доступа к подписям образов.

### Запуск web-сервера sigstore как systemd сервиса

Установите пакет `nginx`:
```
# apt-get install nginx
```
Перейдите в каталог конфигурации, сделайте контекстную замену и аактивируйте конфигурацию:
```
# cd /etc/nginx/sites-enabled.d
# sed -i  -e 's/server_name .*;/server_name sigstore.local;/' -e 's|root .*|root /var/sigstore;|' -e 's/listen .*;/listen 0.0.0.0:81;/' ../sites-available.d/default.conf
# ln -s ../sites-available.d/default.conf .
```
Активируйте сервис:
```
# systemctl enable --now nginx
```
Проверьте в браузере, указав URL `http://sigstore.local:81/` что сервис запущен и слушает порт.
![Проверка работа web-сервера](./testnginx.png)

### Запуск web-сервера sigstore как podman-контейнера (альтернативный способ)

Запустите web-сервер sigstore
```
$ sudo podman run -d -p 81:80 --name sigstore -v /var/sigstore:/var/www/html  registry.altlinux.org/alt/nginx
```
> На момент запуска в файле `/containers/policy.json` или значение `default.type` или значение `transports.docker.registry.altlinux.org.type` должно быть установлено в `insecureAcceptAnything`.

После его запуска
```
$ sudo podman ps
```
<pre>
CONTAINER ID  IMAGE                                   COMMAND               CREATED         STATUS             PORTS                 NAMES
...
2cace2b2e0aa  registry.altlinux.org/alt/nginx:latest  nginx -g daemon o...  18 seconds ago  Up 19 seconds ago  0.0.0.0:81->80/tcp  sigstore
</pre>
web-сервер sigstore будет принимать запросы по порту 81 домена sigstore.local (http://sigstore.local:81/)

Проверьте в браузере, указав URL `http://sigstore.local:81/` что сервис запущен и слушает порт.
![Проверка работа web-сервера](./testnginx.png)

Cоздайте системный сервис и инициализируйте его:
```
$ su - -c 'podman generate systemd -n  sigstore > /lib/systemd/system/sigstore.service' root
```
<pre>
Password:
</pre>
```
$ sudo systemctl enable --now sigstore
```

## Генерация GPG-ключей

> Примечание: для генерацией ключей установите один из `pinentry агентов`. Например:
```
$ sudo apt-get install pinentry-common
```
После создания пользователя сгенерируйте gpg ключ:
```
$ gpg2 --full-generate-key
```
<pre>
gpg (GnuPG) 2.2.40; Copyright (C) 2022 g10 Code GmbH
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

gpg: создан каталог '/home/imagemaker/.gnupg'
gpg: создан щит с ключами '/home/imagemaker/.gnupg/pubring.kbx'
Выберите тип ключа:
   (1) RSA и RSA (по умолчанию)
   (2) DSA и Elgamal
   (3) DSA (только для подписи)
   (4) RSA (только для подписи)
  (14) Имеющийся на карте ключ
Ваш выбор? 1
длина ключей RSA может быть от 1024 до 4096.
Какой размер ключа Вам необходим? (3072)
Запрошенный размер ключа - 3072 бит
Выберите срок действия ключа.
         0 = не ограничен
      <n>  = срок действия ключа - n дней
      <n>w = срок действия ключа - n недель
      <n>m = срок действия ключа - n месяцев
      <n>y = срок действия ключа - n лет
Срок действия ключа? (0)
Срок действия ключа не ограничен
Все верно? (y/N)
GnuPG должен составить идентификатор пользователя для идентификации ключа.

Ваше полное имя: ...
Адрес электронной почты: ...@...
Примечание: ImageMaker Signer
Вы выбрали следующий идентификатор пользователя:
    "... (ImageMaker Signer) <...@...>"
Сменить (N)Имя, (C)Примечание, (E)Адрес; (O)Принять/(Q)Выход?
</pre>
Задайте параметры включая полное имя и Email.
После установки через pinentry-агента пароля генерируется ключ:
<pre>
gpg: /home/imagemaker/.gnupg/trustdb.gpg: создана таблица доверия
gpg: создан каталог '/home/imagemaker/.gnupg/openpgp-revocs.d'
gpg: сертификат отзыва записан в '/home/imagemaker/.gnupg/openpgp-revocs.d/AD413A1450879358C4DE67878F29DF5E5DEF9CA0.rev'.
открытый и секретный ключи созданы и подписаны.
pub   rsa3072 2023-03-02 [SC]
      AD413A1450879358C4DE67878F29DF5E5DEF9CA0
uid                      ... <kaf@...>
sub   rsa3072 2023-03-02 [E]
</pre>

Проверьте наличие ключа:
```
$ gpg2 --list-keys
```
<pre>
/home/imagemaker/.gnupg/pubring.gpg
---------------------------------------
pub   rsa3072 2023-02-22 [SC]
      B85E259BA06AE760573EC79778042BE5D1E452CA
uid         [  абсолютно ] Images Developer &lt;kaf@basealt.ru&gt;
sub   rsa3072 2023-02-22 [E]
</pre>

Сгенерируйте открытый ключ указав uid ключа и записав его в каталог ключей под именем  group1.pgp:
```
$ gpg2 --output /var/sigstore/keys/group1.pgp  --armor --export 'Images Developer &lt;kaf@basealt.ru&gt;'
```

## Запуск регистратора

Если в системе отсутствует регистратор настройте его запуск.

Выберите имя регистратора. Например: registry.local и при отсутсвии DNS-сервера добавьте его в /etc/hosts.
<pre>
&lt;IP-адрес_компьютера&gt; registry.local
</pre>
В качестве `<IP-адрес_компьютера>` необходимо указать адрес компьютера, который будет использоваться другими рабочими местами для доступа к образам.

Создайте именовный том для регистратора:
```
# podman volume create registry
```

Примените один из способов запуска регистратора, описанных ниже (рекомендуется запуск через `systemd`).


### Запуск регистратора как systemd сервиса

Установите пакет `docker-registry`:
```
# apt-get install docker-registry
```
Cделайте контекстную замену файла конфигурации:
```
# sed -i -e 's|rootdirectory:.*|rootdirectory: /var/lib/containers/storage/volumes/registry/_data/|' -e 's/addr:.*/addr: :80/' /etc/docker-registry/config.yml
```
Активируйте сервис:
```
# systemctl enable --now docker-registry
```
Проверьте командой `curl` работу регистратора:
```
# curl -i http://registry.local
```
<pre>
HTTP/1.1 200 OK
Cache-Control: no-cache
Date: Tue, 07 Mar 2023 11:22:25 GMT
Content-Length: 0
</pre>


### Запуск регистратора как podman-контейнера (альтернативный вариант)

Запустите контейнер:
```
$ sudo podman run --name registry -d -p 80:5000 -v registry:/var/lib/docker-registry/docker/registry  registry.altlinux.org/alt/registry
```
После его запуска
```
$ sudo podman ps
```
<pre>
CONTAINER ID  IMAGE                              COMMAND               CREATED         STATUS             PORTS                 NAMES
...
8651b7726a04  registry.altlinux.org/alt/library/registry:latest  /etc/docker/regis...  14 minutes ago  Up 14 minutes ago  0.0.0.0:80->5000/tcp  registry
...
</pre>
Регистратор будет принимать запросы по порту `80` домена `registry.local` (http://registry.local/)

Проверьте командой `curl` работу регистратора:
```
# curl -i http://registry.local
HTTP/1.1 200 OK
Cache-Control: no-cache
Date: Tue, 07 Mar 2023 11:22:25 GMT
Content-Length: 0
```

Создайте системный сервис и инициализируйте его:
```
$ su - -c 'podman generate systemd -n  registry > /lib/systemd/system/registry.service' root
```
<pre>
Login:
</pre>
```
$ sudo systemctl enable --now registry
```

## Настройка электронной подписи образов

Настройте режим работы с `registry` для пользователя `imagemaker`:
```
$ mkdir -p .config/containers/registries.d
$ $EDITOR .config/containers/registries.d/default.yaml
```

Укажите, что для записи подписей образов с префиксом `registry.local` будет использоваться каталог `/var/sigstore/sigstore/`:
```
default-docker:

docker:
  registry.local:
    lookaside: http://sigstore.local/sigstore
    lookaside-staging: file:///var/sigstore/sigstore/
```

## Конфигурация запрета загрузки неподписанных образов в каталоге /etc/containers:

Для всех остальных клиентов доступ к подписям образов для проверки подлинности подписи осуществляется в режиме `ReadOnly` через `http-сервер`:
```
$ sudo $EDITOR /etc/containers/registries.d/default.yaml
```

```
default-docker:
  lookaside: http://sigstore.local:81/sigstore/
  sigstore: http://sigstore.local:81/sigstore/
```
Первый элемент `lookaside` использют пользователи запускающие `podman` и демон `crio` `kubernetes` версии **>= 1.26**.
Второй элемент `sigstore` использует демон `crio` `kubernetes` версии < **1.26**.

Установите политику доступа клиентов к репоэиториям:
```
$ sudo $EDITOR /etc/containers/policy.json
```
```
{
  "default": [
    {
      "type": "reject"
    }
  ],
  "transports": {
    "docker": {
      "registry.local": [
        {
          "type": "signedBy",
          "keyType": "GPGKeys",
          "keyPath": "/var/sigstore/keys/group1.pgp"
        }
      ]
    }
  }
}
```
Для всех клиентов закрыт доступ ко всем репозиториям, кроме `registry.local`.

Загрузка образов
```
$ podman pull registry.local/... 
$ podman run registry.local/...
```
с префиксом `registry.local/...` осуществляется с проверкой подписи образа, доступного по `URL` `http://sigstore.local/sigstore` на основе открытой подписи, хранящейся в файле `/var/sigstore/keys/group1.pgp`.

## Проверка работы электронной подписи на локальном компьютере

### Помещение образов в регистратор

Загрузите какой либо образ, например `registry.altlinux.org/alt/alt`
```
$ podman pull --tls-verify=false registry.altlinux.org/alt/alt
```
> В момент запуска `kernel.unprivileged_userns_clone` должно быть включено:
> ```
> sysctl -w kernel.unprivileged_userns_clone=1
> ```
> `/usr/bin/newuidmap`, `/usr/bin/newgidmap` должны иметь faciities получать права `root`

<pre>
Trying to pull registry.altlinux.org/alt/alt:latest...
Getting image source signatures
Copying blob 9ab3f3206235 skipped: already exists
Copying blob cedd146c7d35 skipped: already exists
Copying config ff2762c6c8 done
Writing manifest to image destination
Storing signatures
ff2762c6c8cc9468e0651364e4347aa5c769d78541406209e9ab74717f29e641
</pre>

Присвойте ему тег `registry.local/alt/alt` из namespace локального регистратора:
```
$ podman tag registry.altlinux.org/alt/alt registry.local/alt/alt
```

Поместите образ на регистратор:
```
$ export GNUPGHOME=$HOME/.gnupg
$ podman push --tls-verify=false  \
  --sign-by='<kaf@basealt.ru>' \
  registry.local/alt/alt
```
<pre>
Getting image source signatures
Copying blob 60bdc4ff8a54 done
Copying blob 9a03b2bc42d8 done
Copying config ff2762c6c8 done
Writing manifest to image destination
Signing manifest using simple signing
Storing signatures
</pre>
Во время подписывания изображения система попросит Вас ввести пароль, заданный при генерации `gpg-ключей`.

![Ввод пароля](./setpass.png)
Проверьте, что подпись  образа сохранилась в `sigstore`:
```
$ du  /var/sigstore/sigstore/
```
<pre>
8,0K    /var/sigstore/sigstore/alt/alt@sha256=160a6691c4c9c373461974dcf4c1e06ed221ce76275387e4e35ed69593f341c5
12K     /var/sigstore/sigstore/alt
16K     /var/sigstore/sigstore/
</pre>
и поместилась в регистратор:
```
$ sudo du -s /var/lib/containers/storage/volumes/registry/_data/docker/registry/v2/repositories/alt/alt/
```
<pre>
4       /var/lib/containers/storage/volumes/registry/_data/v2/repositories/alt/alt/_uploads
8       /var/lib/containers/storage/volumes/registry/_data/v2/repositories/alt/alt/_manifests/revisions/sha256/160a6691c4c9c373461974dcf4c1e06ed221ce76275387e4e35ed69593f341c5
12      /var/lib/containers/storage/volumes/registry/_data/v2/repositories/alt/alt/_manifests/revisions/sha256
16      /var/lib/containers/storage/volumes/registry/_data/v2/repositories/alt/alt/_manifests/revisions
8       /var/lib/containers/storage/volumes/registry/_data/v2/repositories/alt/alt/_manifests/tags/latest/current
...
</pre>

### Загрузка клиентами образа с регистратора

#### Создание клиента

*Администратор безопасности средства контейнеризации*
создает пользователя (например `user`) входящего в группу `podman`:
```
$ sudo adduser user
$ sudo passwd user
```
```
$ sudo usermod -a -G podman user
$ sudo mkdir -p ~user/.config/containers
$ sudo cat > ~user/.config/containers/storage.conf
$ sudo chmod -R 500 ~user/.config/containers
$ sudo chown -R user:podman ~user/.config/containers
$ sudo chattr +i  ~user/.config/containers
```
Для того, чтобы клиент не смог изменить системные настройки заданные в  каталоге `/etc/containers` клиентский каталог настроек `~user/.config/containers` закрывается для доступа и изменения.

#### Загрузка образов

Зайдите в созданного пользователя и выполните загрузку образа:
```
$ podman pull --tls-verify=false registry.local/alt/alt
```
<pre>
Trying to pull registry.local/alt/alt:latest...
Getting image source signatures
Checking if image destination supports signatures
Copying blob ae1b6f30172a done
Copying blob 87ff05e10cc3 done
Copying config ff2762c6c8 done
Writing manifest to image destination
Storing signatures
ff2762c6c8cc9468e0651364e4347aa5c769d78541406209e9ab74717f29e641
</pre>

Проверьте запрет на скачивание образа при неверном ключе.
Под администратором скопируйте открытый ключ и измение его:
```
# cp /var/sigstore/keys/group1.pgp  /tmp
# echo aaa > /var/sigstore/keys/group1.pgp
```

В этом случае загрузка образа пройдет неудачно:
```
$ podman pull --tls-verify=false registry.local/alt/alt
```
<pre>
Trying to pull registry.local/alt/alt:latest...
Error: Source image rejected: No public keys imported
</pre>

Верните подпись на место:
```
# cp /tmp/group1.pgp /var/sigstore/keys/
```

## Проверка работы электронной подписи на удаленном компьютере

### Настройка системных файлов

#### /etc/hosts

Если `DNS` не поддерживается сформируйте файл `/etc/hosts`:
<pre>
&lt;IP-адрес_компьютера_разработчика_образов&gt; sigstore.local
&lt;IP-адрес_компьютера_разработчика_образов&gt; registry.local
</pre>
В качестве `<IP-адрес_компьютера_разработчика_образов>` необходимо указать адрес компьютера, который будет использоваться другими рабочими местами для доступа к подписям образов.

### Загрузка открытого ключа

Создайте каталог `/var/sigstore/keys/`:
```
# mkdir -p /var/sigstore/keys/
# chown root:podman /var/sigstore/keys/
```

Скопируйте открытый ключ:
```
# curl -k http://sigstore.local:81/keys/group1.pgp > /var/sigstore/keys/group1.pgp
# chown root:podman /var/sigstore/keys/group1.pgp
```


### Конфигурация запрета загрузки неподписанных образов в каталоге /etc/containers:

Смотри раздел
*Конфигурация запрета загрузки неподписанных образов в каталоге /etc/container*
описанный выше

### Загрузка клиентами образа с регистратора

Смотри раздел
*Загрузка клиентами образа с регистратора*
описанный выше
