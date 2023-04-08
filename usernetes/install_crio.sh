#!/bin/sh

User=u7s-admin

cp -r /etc/containers/ /home/${User}/.config/usernetes/
# cp /etc/containers/registries.conf  /home/${User}/.config/usernetes/containers/registries.conf
(
cd /home/${User}/.config/
ln -sf usernetes/containers .
)
chown -R user:user /home/${User}/
./install.sh --cri=crio --cni=flannel
cp /home/user/.config/usernetes/master/admin-localhost.kubeconfig /home/${User}/.kube/config
chown -R user:user /home/${User}/.kube
