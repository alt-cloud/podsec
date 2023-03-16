#!/bin/sh

# Создание пользователя $user
createImageMaker() {
  user=$1
  linkedPolicyFile=$linkedPolicyFile
  groupadd -r podman
  groupadd -r podman_dev
  adduser $user -g podman -G podman_dev,fuse
  echo "Введите пароль разработчика образов контейнеров"
  passwd $user

  cd /home/$user

  mkdir -p .config/containers/
  cat <<EOF > .config/containers/storage.conf
[storage]
driver = "overlay"
[storage.options.overlay]
mount_program = "/usr/bin/fuse-overlayfs"
mountopt = "nodev,metacopy=on"
EOF

  TMPFILE="/tmp/createImageMakerUser.$$"
  jq '.transports.docker."registry.local"[.transports.docker."registry.local"| length] |= . +
  {"type": "signedBy","keyType": "GPGKeys","keyPath": "/var/sigstore/keys/'$user'.pgp"}' /etc/containers/$linkedPolicyFile > $TMPFILE &&
  mv $TMPFILE /etc/containers/$linkedPolicyFile

  echo '{"default":[{"type":"insecureAcceptAnything"}],"transports":{"docker": {"registry.local":[]}}}' |
  jq . > .config/containers/policy.json
  mkdir -p .config/containers/registries.d
  sigStoreURL="http://sigstore.local:81/sigstore/"
  refs="{\"lookaside\":\"$sigStoreURL\""
  refs+=", \"sigstore\":\"$sigStoreURL\""
  refs+=", \"lookaside-staging\": \"file:///var/sigstore/sigstore/\""
  refs+=", \"sigstore-staging\": \"file:///var/sigstore/sigstore/\"}"
  echo "{\"default-docker\":$refs}" | yq -y . > .config/containers/registries.d/default.yaml
  echo "{\"docker\":{\"registry.local\":$refs}}" | yq -y . > .config/containers/registries.d/sigstore_local.yaml
  chown -R $user:podman .

  su - -c 'gpg2 --full-generate-key'  $user
  set -- $(su - -c 'gpg2 --list-keys'  $user)
  if [ $# -lt 1 ]
  then
    echo "Не найден открытый ключ"
    exit 1
  fi
  # Вытащить uid из ключа
  while [ $# -gt 1 ]; do shift; if [ ${1:0:1} == '<' ]; then break; fi  done
  uid=$1
  su - -c "gpg2 --output /var/sigstore/keys/$user.pgp  --armor --export '$uid'" $user
}

#MAIN
if [ $# -eq 0 ]
then
  users='imagemaker'
else
  users=$*
fi

sysctl -w kernel.unprivileged_userns_clone=1
# Это надо будет заменить на control
chown root:podman /usr/bin/newuidmap /usr/bin/newgidmap
chmod 6750 /usr/bin/newuidmap /usr/bin/newgidmap
# setcap cap_setgid,cap_setuid=ep  /usr/bin/newuidmap
# setcap cap_setgid,cap_setuid=ep  /usr/bin/newgidmap

if [ ! -d /var/sigstore/ ]
then
  mkdir -p -m 0775 /var/sigstore/keys/
  chown root:podman_dev /var/sigstore/keys/
  mkdir -p -m 0775 /var/sigstore/sigstore/
  chown root:podman_dev /var/sigstore/sigstore/
  echo '<html><body><h1>SigStore works!</h1></body></html>' > /var/sigstore/index.html
fi

yesterday=$(date '+%Y-%m-%d_%H:%M:%S' -d "yesterday")
if [ ! -L $policyFile ]
then :;
  mv $policyFile ${policyFile}_${yesterday}
fi
now=$(date '+%Y-%m-%d_%H:%M:%S')
linkedPolicyFile="policy_${now}"
cd /etc/containers/
cp -L policy.json $linkedPolicyFile
for user in $users
do
  createImageMaker $user $linkedPolicyFile
done

cd /etc/containers/
if jq . $linkedPolicyFile >/dev/null 2>&1
then
  ln -sf $linkedPolicyFile policy.json
fi

for policyFile in /home/*/.config/containers/policy.json
do
  jq '.default[0].type="insecureAcceptAnything"' /etc/containers/policy.json > $policyFile
done
