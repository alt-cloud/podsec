podsec-create-imagemakeruser(1) -- create container image maker users
================================================= 

## SYNOPSIS

`podsec-create-imagemakeruser [username[@repo_path]] ...` 

## DESCRIPTION 

The script creates container image maker users with the following rights: - change the password set by the containerization tool security administrator;
- create, modify, and delete container images.

When creating each user, you must specify: - `user password`;

- `key type`: `RSA`, `DSA and Elgamal`, `DSA (signing only)`, `RSA (signing only)`, `key available on the card`;

- `key expiration date`;

- `full name`;

- `Email` (used later to sign images);

- `note`;

- `password for signing images`.

The script must be called after calling the `podsec-create-policy` script ## OPTIONS The list of users and the registrar paths for which they sign images are passed as parameters in the format: `username@repository_path` - The list must not contain users with the same paths.

- If the user is the only one and the path is not specified, then the `registry.local` path is accepted - If the user name is not specified, the name `imagemaker@registry.local` is accepted as the first parameter.

## EXAMPLES 

`podsec-create-imagemakeruser immkk8s@registry.local/k8s-c10f1 imklocal@registry.local immkalt@registry.altlinux.org` Three users with signing rights are created: - `immkk8s` - local kubernetes images with the path `registry.local/k8s-c10f1`;

- `imklocal` - local `registry.local` images except kubernetes images - `immkalt` - registrar images `registry.altlinux.org` ## SECURITY CONSIDERATIONS - This script should only be run on a node with the `registry.local` , `sigstore-local` domains. If this is not the case, the script stops.

- Image developers must control the list of signed images themselves. If the user `imklocal` signs an image with the path `registry.local/k8s-c10f1`, then the deployment of this image will fail, since the public key of the user `immkk8s` will be used for signature verification, not ` imklocal`.

- All users created in the cluster must be located on the same server with the `storage.local` domain. The WEB server for image signatures must also be deployed there.

- All public keys of users are located in the `/var/sigstore/keys/` directory and must be copied to each server in the cluster to the `/var/sigstore/keys/` directory - Image signatures are stored in the ` /var/sigstore/sigstore/` directory with the registrar names discarded. if the system controls signatures of images from different registrars (for example: `registry.altlinux.org` and `registry.local`) and the image `registry.local/k8s-c10f1/pause:3.9` with `@sha256 \=347a15493d0a38d9ce74f23ea9f081583728a20dbdc11d7c17ef286d9cade3ec` is signed, then all images with this `sha256` will be considered signed: `registry.altlinux.orh/k8s-c10f1/pause:3.9`, ... ## SEE ALSO - [Con tainer image maker]( https://github.com/alt-cloud/podsec/tree/master/SigningImages).

- [Description of periodic integrity monitoring of container images and containerization tool settings](https://github.com/alt-cloud/podsec/tree/master/ImageSignatureVerification)


## AUTHOR 

Aleksey Kostarev, Basealt LLC kaf@basealt.ru
