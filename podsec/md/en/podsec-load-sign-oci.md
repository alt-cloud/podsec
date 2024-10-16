podsec-load-sign-oci(1) -- unpacking images from a compressed `xz-oci-archive`, signing them and placing them on the registry
=================================

## SYNOPSIS

`podsec-load-sign-oci archive_file_name signer_mail_architecture [registrar/path]`

## DESCRIPTION

Script:

- extracts images from a compressed `xz-oci-archive`,

- unpacks them in the file system,

- signs them and places them on the registrar along the specified path.

## OPTIONS

1. The `oci-file archive` passed as the first parameter must be compressed with the `xz` compressor.

2. `Architecture name` must be in the list `amd64`, `arm64`, `arm`, `ppc64le`, `386`.

3. `Signer_EMail` must be specified in the user signature and is specified without the enclosing `<>` brackets.

4. `registrar/path` must contain the name of the registrar subdirectory. The format `registrar` is invalid
If `registrar/path` is not specified, the path `registry.local/k8s-c10f1` is assumed

## EXAMPLES

`podsec-load-sign-oci /mnt/cdrom/containers/amd64.tar.xz amd64 immklocal@baseat.ru registry.local`

`podsec-load-sign-oci /mnt/cdrom/containers/amd64.tar.xz amd64 immkk8s@baseat.ru`

## SECURITY CONSIDERATIONS

- This script should only be run on a node with the `registry.local`, `sigstore-local` domains. If this is not the case, the script will stop working.

- The script should be called by a user belonging to the `podman_dev` group.

## AUTHOR

Kostarev Alexey, Basalt SPO
kaf@basealt.ru
