#!/bin/sh

# Установка пакетов
apt-get update
apt-get -y install fuse-overlayfs

groupadd -r podman 2 >/dev/null
for user
do
  adduser $user -g podman
  echo "Введите пароль пользователя '$user':"
  passwd $user
  cd /home/$user
  mkdir -p .config/containers
  cat <<EOF > .config/containers/storage.conf
[storage]
driver = "overlay"
[storage.options.overlay]
mount_program = "/usr/bin/fuse-overlayfs"
mountopt = "nodev,metacopy=on"
EOF
  chmod -R 500 .config/containers
  chown -R $user:podman .config/containers
  chattr +i  .config/containers
done
