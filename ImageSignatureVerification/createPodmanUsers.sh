#!/bin/sh

groupadd -r podman 2 >/dev/null
for user
do
  adduser $user -g podman
  echo "Введите пароль пользователя '$user':"
  passwd $user
  cd /home/$user
  mkdir -p .config/containers
  cp /etc/containers/storage.conf .config/containers/storage.conf
  chmod -R 500 .config/containers
  chown -R $user:podman .config/containers
  chattr +i  .config/containers
done
