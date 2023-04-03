#!/bin/sh

if [ $(id -u) -ne 0 ]
then
  echo "Скрипт должен запускаться пользователем с права-ми root"
  exit 1
fi

if [ $# -eq 0 ]
then
  echo -ne "Формат:\n$0 <username> ...\n"
  exit 1
fi
groupadd -r podman 2>/dev/null
for user
do
  adduser $user -g podman -G fuse
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
  chattr +i -R .config/containers
done
