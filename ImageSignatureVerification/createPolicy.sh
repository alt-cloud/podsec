#!/bin/sh
# Скрипт создает

if [ $# -lt 1 ]
then
  echo -ne "Не указан IP-адрес регистратора и сервера подписей\n"
  echo -ne "Формат:\n\t$0 <ip-адрес_регистратора_и_сервера_подписей>\n"
  exit 1
fi
regIP=$1

case $regIP in
  '127.0.0.1')
    echo "IP-адрес регистратора и сервера подписей не должен быть локальным: $regIP"
    exit 1;;
esac

ifs=$IFS IFS=.
set -- $regIP
IFS=$ifs
if [ $# -ne 4 ]
then
  echo "Некорректный IP-адрес: $regIP"
  exit 2
fi

for ip
do
  if [[ "$a" =~ $re && "$a" -ge 0 && "$a" -lt 256 ]]
  then :;
  else
  echo "Некорректный IP-адрес: $regIP"
    exit 3
  fi
done

# Создание групп
groupadd -r podman
groupadd -r podman_dev

# Поддержка возможности работа в rootless режиме
echo kernel.unprivileged_userns_clone=1 > /etc/sysctl.d/99-podman.conf
sysctl -w kernel.unprivileged_userns_clone=1

# Это надо будет заменить на control
chown root:podman /usr/bin/newuidmap /usr/bin/newgidmap
chmod 6750 /usr/bin/newuidmap /usr/bin/newgidmap
# setcap cap_setgid,cap_setuid=ep  /usr/bin/newuidmap
# setcap cap_setgid,cap_setuid=ep  /usr/bin/newgidmap

localIP=
if ip a  | grep $regIP >/dev/null 2>&1
then
  localIP='yes'
fi


if line=$(grep $regIP /etc/hosts 2>/dev/null)
then
  set -- $line
  ip=$1
  shift
  while domain
  do
    if [ $domain == 'registry.local' || $domain == 'sigstore.local' ]
    then
      echo "Домены registry.local sigstore.local уже привязаны к IP-адресу $ip" >&2
      echo "Удалите привязку и запустите скрипт заново" >&2
      exit 1
    fi
  done
else
  echo "Добавление привязки доменов registry.local sigstore.local к IP-адресу $regIP"
  echo "$regIP registry.local sigstore.local" >> /etc/hosts
fi

# Создание группы podman
echo "Создание группы podman"
groupadd -r podman
echo "Инициализация каталога /var/sigstore/ и подкаталогов хранения открытых ключей и подписей образов"
# Создание каталога и подкаталогов  /var/sigstore/ если IP-адрес узла совпадает с IP-адресом сервера подписей storage.local
echo "Создание каталога и подкаталогов  /var/sigstore/"
mkdir -p -m 0775 /var/sigstore/keys/
if [ -n "$localIP" ]
then
  #IP-адрес узла совпадает с IP-адресом сервера подписей storage.local
  echo "Создание группы podman_dev"
  groupadd -r podman_dev
  # Создать каталог sogstore с подкаталогами
  chown root:podman_dev /var/sigstore/keys/
  mkdir -p -m 0775 /var/sigstore/sigstore/
  chown root:podman_dev /var/sigstore/sigstore/
  echo '<html><body><h1>SigStore works!</h1></body></html>' > /var/sigstore/index.html
else
  chown root:podman /var/sigstore/keys/
fi

# Создание файла политик /etc/containers/policy.json и файла /etc/containers/registries.d/default.yaml описания доступа к открытым ключам подписантов
cd /etc/containers

# Создание registries.d/default.yaml

suffix=$(date '+%Y-%m-%d_%H:%M:%S')
policyFile='policy.json'
yesterday=$(date '+%Y-%m-%d_%H:%M:%S' -d "yesterday")
now=$(date '+%Y-%m-%d_%H:%M:%S')

# Создание с сохранением предыдущих файла политик /etc/containers/policy.json
echo "Создание с сохранением предыдущих файла политик /etc/containers/policy.json"
if [ ! -L $policyFile ]
then :;
  mv $policyFile "policy_${yesterday}"
fi
linkedPolicyFile="policy_${now}"
echo '{"default":[{"type":"reject"}], "transports":{"docker": {}}}' |
jq . > $linkedPolicyFile
ln -sf $linkedPolicyFile $policyFile

# Создание с сохранением предыдущих файла `/etc/containers/registries.d/default.yaml` описания доступа к открытым ключам подписантов
echo "Создание с сохранением предыдущих файл /etc/containers/registries.d/default.yaml описания доступа к открытым ключам подписантов"
cd /etc/containers/registries.d
defaultYaml='default.yaml'
if [ ! -L $defaultYaml ]
then :;
  mv $defaultYaml ${defaultYaml}.${yesterday}
fi
linkedDefaultYaml="default_${now}"
sigStoreURL="http://sigstore.local:81/sigstore/"
refs="\"lookaside\":\"$sigStoreURL\", \"sigstore\":\"$sigStoreURL\""
refs="{$refs}"
echo "{\"default-docker\":$refs}" | yq -y . > $linkedDefaultYaml
ln -sf $linkedDefaultYaml $defaultYaml

cd /etc/containers
# Добавление insecure-доступа к регистратору registry.local в файле /etc/containers/registries.conf
echo "Добавление insecure-доступа к регистратору registry.local в файле /etc/containers/registries.con"
registriesConf="registries.conf"
if [ ! -L $registriesConf ]
then :;
  cp $registriesConf ${registriesConf}.${yesterday}
fi
linkedRegistriesConf="registries_${now}"
if grep '^location.*=.*registry.local' $registriesConf > /dev/nul 2>&1
then :;
else
  cp $registriesConf $linkedRegistriesConf
  echo -ne "\n[[registry]]\nlocation = \"registry.local\"\ninsecure = true\n" >> $linkedRegistriesConf
  ln -sf $linkedRegistriesConf  $registriesConf
fi

# Настройка использования образа registry.local/k8s-p10/pause:3.7 при запуска pod'ов в podman (podman pod init)
echo "Настройка использования образа registry.local/k8s-p10/pause:3.7 при запуска pod'ов в podman (podman pod init)"
sed -i -e 's|#infra_image =.*|infra_image = "registry.local/k8s-p10/pause:3.7"|' /usr/share/containers/containers.conf

if [ -z "$localIP" ]
then
  echo "Файл политик /etc/containets/policy.json созадется на сервере '$regIP' при создании пользователей подписывающих образы.\
  Скопируйте этот  файл c '$regIP' после добавления этих пользователей."
fi


