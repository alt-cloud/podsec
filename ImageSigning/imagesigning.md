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
> <pre> 
> insecure_registries = [
>  "registry.local"
> ]
> </pre>

> Существенное дополнение.
> Текущая версия пакета  cri-o в дистрибутиве - **1.24.3**
> <pre>
> # rpm -qa | grep cri-o
> cri-o-1.24.3-alt1.x86_64
> </pre>
> Поддержка файлов формата containers-registries.d (https://github.com/containers/image/blob/main/docs/>containers-registries.d.5.md) в cri-o появилась версии cri-o *v1.26.0* (текущая  v1.26.1 https://github.com/cri-o/cri-o/releases/tag/v1.26.1)
> Для поддержки механизма загрузки подписанных сообщений **необходимо обновить пакет cri-o до версии v1.26.1**



# Разработчик образов контейнеров 

Пользователь входит в группы podman, podman_dev, wheel.

## Включение возможности загрузки образов для разработчика образов контейнеров

Для поддержки всех типов транспорта создайте файл-конфигурации ~/.config/containers/policy.json:
<pre>
$ $EDITOR ~/.config/containers/policy.json
</pre>
<pre>
{
  "default": [
    {
      "type": "insecureAcceptAnything"
    }
  ]
}
</pre>

## Запуск web-сервера sigstore для хранения ключей и подписей образов

Выберите имя регистратора. Например: sigstore.local и при отсутсвии DNS-сервера добавьте его в /etc/hosts.
<pre>
&lt;IP-адрес_компьютера&gt; sigstore.local
</pre>
В качестве &lt;IP-адрес_компьютера&gt; необходимо указать адрес компьютера, который будет использоваться другими рабочими местами для доступа к подписям образов. 

Создайте каталоги для хранения ключей и подписей образов:
<pre>
$ sudo mkdir -p -m 0775 /var/sigstore/keys/
$ sudo chown root:podman_dev /var/sigstore/keys/
$ sudo mkdir -m 0775 /var/sigstore/sigstore/
$ sudo chown root:podman_dev /var/sigstore/sigstore/
</pre>

Запустите web-сервер sigstore
<pre>
$ sudo podman  run -d -p 81:80 --name sigstore -v /var/sigstore:/var/www/html  registry.altlinux.org/alt/nginx
</pre>
После его запуска 
<pre>
$ sudo podman ps
CONTAINER ID  IMAGE                                   COMMAND               CREATED         STATUS             PORTS                 NAMES
...
2cace2b2e0aa  registry.altlinux.org/alt/nginx:latest  nginx -g daemon o...  18 seconds ago  Up 19 seconds ago  0.0.0.0:81->80/tcp  sigstore
</pre>
web-сервер sigstore будет принимать запросы по порту 81 домена sigstore.local (http://sigstore.local:81/) 

Cоздайте системный сервис и инициализируйте его:
<pre>
$ su - -c 'podman generate systemd -n  sigstore > /lib/systemd/system/sigstore.service' root
$ sudo systemctl enable --now sigstore
</pre>

## Генерация GPG-ключей 
После создания пользователя сгенерируйте gpg ключ:
<pre>
$ gpg2 --full-generate-key
</pre>
Задайте параметры включая полное имя и Email.

Проверьте наличие ключа:
<pre>
$ gpg2 --list-keys
/home/imagedeveloper/.gnupg/pubring.gpg
---------------------------------------
pub   rsa3072 2023-02-22 [SC]
      B85E259BA06AE760573EC79778042BE5D1E452CA
uid         [  абсолютно ] Images Developer &lt;kaf@basealt.ru&gt;
sub   rsa3072 2023-02-22 [E]
</pre>

Сгенерируйте открытый ключ указав uid ключа и записав его в каталог ключей под именем  group1.pgp:
<pre>
$ gpg2 --output /var/sigstore/keys/group1.pgp  --armor --export 'Images Developer &lt;kaf@basealt.ru&gt;'
</pre>

## Запуск регистратора

Выберите имя регистратора. Например: registry.local и при отсутсвии DNS-сервера добавьте его в /etc/hosts.
<pre>
&lt;IP-адрес_компьютера&gt; registry.local
</pre>
В качестве &lt;IP-адрес_компьютера&gt; необходимо указать адрес компьютера, который будет использоваться другими рабочими местами для доступа к образам.

Если в системе отсутствует регистратор настройте его запуск.
<pre>
$ sudo podman run --name registry -d -p 80:5000 -v registry:/var/lib/registry  docker.io/registry</pre>
</pre>
После его запуска 
<pre>
$ sudo podman ps
CONTAINER ID  IMAGE                              COMMAND               CREATED         STATUS             PORTS                 NAMES
8651b7726a04  docker.io/library/registry:latest  /etc/docker/regis...  14 minutes ago  Up 14 minutes ago  0.0.0.0:80->5000/tcp  registry
</pre>
Регистратор будет принимать запросы по порту 80 домена registry.local (http://registry.local/) 

Создайте системный сервис и инициализируйте его:
<pre>
$ su - -c 'podman generate systemd -n  registry > /lib/systemd/system/registry.service' root
$ sudo systemctl enable --now registry
</pre>

## Настройка электронной подписи образов

Настройте режим работы с registry для пользователя imagedeveloper:
<pre>
$ mkdir -p .config/containers/registries.d
$ $EDITOR .config/containers/registries.d/default.yaml
</pre>

Укажите, что для записи подписей образов с префиксом registry.local будет использоваться каталог /var/sigstore/sigstore/:
<pre>
default-docker:

docker:
  registry.local:
    lookaside: http://sigstore.local/sigstore
    lookaside-staging: file:///var/sigstore/sigstore/
</pre>

## Конфигурация запрета загрузки неподписанных образов в каталоге /etc/containers:

Для всех остальных клиентов доступ к подписям образов для проверки подлинности подписи осуществляется в режиме RO через http-сервер:
<pre>
$ sudo $EDITOR /etc/containers/registries.d/default.yaml
</pre>

<pre>
default-docker:
  lookaside: http://sigstore.local:81/sigstore/
</pre>

Установите политику доступа клиентов к репоэиториям:
<pre>
$ sudo $EDITOR /etc/containers/policy.json
</pre>
<pre>
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
</pre>
Для всех клиентов закрыт доступ ко всем репозиториям, кроме registry.local.

Загрузка образов (podman pull registry.local/..., podman run registry.local/...) с префиксом registry.local/... осуществляется с проверкой подписи образа, доступного по URL http://sigstore.local/sigstore на основе открытой подписи, хранящейся в файле /var/sigstore/keys/group1.pgp. 


## Проверка работы электронной подписи на локальном компьютере

### Помещение образов в регистратор

Загрузите какой либо образ, например registry.altlinux.org/alt/alt
<pre>
$ podman pull --tls-verify=false registry.altlinux.org/alt/alt
Trying to pull registry.altlinux.org/alt/alt:latest...
Getting image source signatures
Copying blob 9ab3f3206235 skipped: already exists  
Copying blob cedd146c7d35 skipped: already exists  
Copying config ff2762c6c8 done  
Writing manifest to image destination
Storing signatures
ff2762c6c8cc9468e0651364e4347aa5c769d78541406209e9ab74717f29e641
</pre>

Присвойте ему тег registry.local/alt/alt из namespace локального регистратора:
<pre>
$ podman tag registry.altlinux.org/alt/alt registry.local/alt/alt
</pre>

Поместите образ на регистратор:
<pre>
$ export GNUPGHOME=$HOME/.gnupg
$ podman push --tls-verify=false  \
  --sign-by='Images Developer &lt;kaf@basealt.ru&gt;' \
  registry.local/alt/alt
Getting image source signatures
Copying blob 60bdc4ff8a54 done  
Copying blob 9a03b2bc42d8 done  
Copying config ff2762c6c8 done  
Writing manifest to image destination
Signing manifest using simple signing
Storing signatures
</pre>
Во время подписывания изображения система попросит Вас ввести пароль, заданный при генерации gpg-ключей.

![Ввод пароля](./setpass.png)
Проверьте, что подпись  образа сохранилась в sigstore:
<pre>
$ du  /var/sigstore/sigstore/
8,0K    /var/sigstore/sigstore/alt/alt@sha256=160a6691c4c9c373461974dcf4c1e06ed221ce76275387e4e35ed69593f341c5
12K     /var/sigstore/sigstore/alt
16K     /var/sigstore/sigstore/
</pre>
и поместилась в регистратор:
<pre>
$ sudo du -s /var/lib/containers/storage/volumes/registry/_data/docker/registry/v2/repositories/alt/alt/*
32K     /var/lib/containers/storage/volumes/registry/_data/docker/registry/v2/repositories/alt/alt/_layers
52K     /var/lib/containers/storage/volumes/registry/_data/docker/registry/v2/repositories/alt/alt/_manifests
4,0K    /var/lib/containers/storage/volumes/registry/_data/docker/registry/v2/repositories/alt/alt/_uploads
</pre>

### Загрузка клиентами образа с регистратора 

#### Создание клиента 

Администратор безопасности средства контейнеризации 
создает пользователя (например user) входящего в группу podman:
<pre>
$ sudo mkdir user 
$ sudo passwd user
$ sudo usermod -a -G podman user
$ sudo mkdir ~user/.config/containers
$ sudo chmod 000 ~user/.config/containers
$ sudo chattr +i  ~user/.config/containers
</pre>
Для того, чтобы клиент не смог изменить системные настройки заданные в  каталоге /etc/containers клиентский каталог настроек ~user/.config/containers закрывается для доступа и изменения.

#### Загрузка образов

Зайдите в созданного пользователя и выполните загрузку образа:
<pre>
$ podman pull --tls-verify=false registry.local/alt/alt
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
Под админстратором скопируйте открытый ключ и измение его:
<pre>
# cp /var/sigstore/keys/group1.pgp  /tmp
# echo aaa > /var/sigstore/keys/group1.pgp
</pre>

В этом случае загрузка образа пройдет неудачно:
<pre>
$ podman pull --tls-verify=false registry.local/alt/alt
Trying to pull registry.local/alt/alt:latest...
Error: Source image rejected: No public keys imported
</pre>

Верните подпись на место:
<pre>
# cp /tmp/group1.pgp /var/sigstore/keys/  
</pre>


## Проверка работы электронной подписи на удаленном компьютере

### Настройка системных файлов

#### /etc/hosts 

Если DNS не поддерживается сформируйте файл /etc/hosts:
<pre>
&lt;IP-адрес_компьютера_разработчика_образов&gt; sigstore.local
&lt;IP-адрес_компьютера_разработчика_образов&gt; registry.local
</pre>
В качестве &lt;IP-адрес_компьютера_разработчика_образов&gt; необходимо указать адрес компьютера, который будет использоваться другими рабочими местами для доступа к подписям образов. 

### Загрузка открытого ключа

Создайте каталог /var/sigstore/keys/:
<pre>
# mkdir -p /var/sigstore/keys/
# chown root:podman /var/sigstore/keys/
</pre>

Скопируйте открытый ключ:
<pre>
# curl -k http://sigstore.local:81/keys/group1.pgp > /var/sigstore/keys/group1.pgp
# chown root:podman /var/sigstore/keys/group1.pgp
</pre>


### Конфигурация запрета загрузки неподписанных образов в каталоге /etc/containers:

Смотри раздел
*Конфигурация запрета загрузки неподписанных образов в каталоге /etc/container*
описанный выше

### Загрузка клиентами образа с регистратора 

Смотри раздел
*Загрузка клиентами образа с регистратора*
описанный выше
