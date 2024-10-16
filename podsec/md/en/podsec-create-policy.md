podsec-create-policy(1) -- creating system policies and configuration files
=================================

## SYNOPSIS

`podsec-create-policy ip-address_of_registrar_and_signature_server`

## DESCRIPTION

The script creates policy files and configures system services for `podman` to work in both `rootfull` and `rootless` modes:

- Adds to the `/etc/hosts` file a binding of the `registry.local`, `sigstore.local` domains to the specified `ip-address_of_registrar_and_signature_server`;

- Creates, preserving the previous policy file `/etc/containers/policy.json`;

- Creates and preserves the previous file `/etc/containers/registries.d/default.yaml` describing access to signatories' public keys;

- Creates the group `podman`;

- If the `ip-address_of_the_registrar_and_signature_server` matches the local IP-address, creates the group `podmen_dev` and initializes the directory `/var/sigstore/` and subdirectories for storing public keys and image signatures;

- Adds insecure access to the registrar `registry.local` to the file `/etc/containers/registries.conf`;

- Configures the use of the image `registry.local/k8s-c10f1/pause:3.9` when starting `pod`s in `podman` (`podman pod init`);

## SECURITY CONSIDERATIONS

- The IP address of the registrar and signature server must not be local `127.0.0.1`

- If the binding of the domains `registry.local`, `sigstore.local` in the file `/etc/hosts` already exists, the script terminates with the exit code `1`. It is necessary to remove the binding line and restart the script.

- If the script is run on a cluster node other than `sigstore.local`, then after the script has run, it is necessary to copy the policy file `/etc/containets/policy.json` from the node `sigstore.local` to the corresponding directory `/etc/containets/`. This operation must be performed each time a user signing images on `sigstore.local` is added.

## SEE ALSO

- [Description of periodic integrity monitoring of container images and containerization tool settings](https://github.com/alt-cloud/podsec/tree/master/ImageSignatureVerification)

## AUTHOR

Aleksey Kostarev, Basealt SPO
kaf@basealt.ru
