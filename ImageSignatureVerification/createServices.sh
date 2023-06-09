#!/bin/sh

. podsec-functions

mes=$(isSigstoreServer)
if [ -n "$mes" ]
then
  echo -ne $mes >&2
  echo "Запуск сервисов невозможен." >&2
  exit 1
fi

# Настройка sigStore
cd /etc/nginx/sites-enabled.d
sed -i  -e 's/server_name .*;/server_name sigstore.local;/' -e 's|root .*|root /var/sigstore;|' -e 's/listen .*;/listen 0.0.0.0:81;/' ../sites-available.d/default.conf
ln -sf ../sites-available.d/default.conf .
systemctl enable --now nginx

# Настройка registry
podman volume create registry
sed -i -e 's|rootdirectory:.*|rootdirectory: /var/lib/containers/storage/volumes/registry/_data/|' -e 's/addr:.*/addr: :80/' /etc/docker-registry/config.yml
if systemctl | grep httpd2 | grep running >/dev/null 2>&1
then
  echo "Сервис httpd2 запущен и конфликтует с docker-registry"
  echo "Сервис httpd2 остановлен"
  systemctl disable --now httpd2
fi
systemctl enable --now docker-registry
