podsec-create-services(1) -- create services to support the docker image registrar and image signature server
==================================

## SYNOPSIS

`podsec-create-services`

## DESCRIPTION

The script starts the `docker-registry` and `nginx` services to support the docker image registrar and image signature server.

- the image registrar accepts requests at `http://registry.local` and stores images in the `/var/lib/containers/storage/volumes/registry/_data/` directory;

- the image signature service accepts requests at `http://sigstore.local:81`, stores image signatures in the `/var/sigstore/sigstore/` directory, public keys in the `/var/sigstore/keys/` directory

## SECURITY CONSIDERATIONS

This script should only be run on a node with the `registry.local`, `sigstore-local` domains, where users creating and signing images are located. If this is not the case, the script stops its work without starting the services.

## SEE ALSO

- [Description of periodic integrity monitoring of container images and containerization tool settings](https://github.com/alt-cloud/podsec/tree/master/ImageSignatureVerification)

## AUTHOR

Aleksey Kostarev, Basalt LLC
kaf@basealt.ru
