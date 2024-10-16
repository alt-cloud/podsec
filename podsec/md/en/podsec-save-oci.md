podsec-save-oci(1) -- archiving images of different architectures to the directory specified by the first parameter, followed by compression and formation of an `xz-oci-archive`
==================================

## SYNOPSIS

`podsec-save-oci image_archiving_directory architecture,architecture,...|all image ...`

## DESCRIPTION

## OPTIONS

- The script archives images to the directory specified by the first parameter

- The second parameter specifies the architectures to be archived, separated by commas. If the second parameter is all, all architectures are archived: `amd64`, `arm64`, `arm ppc64le`, `386`.

- The script downloads the images specified by the 3rd and subsequent parameters from the registrar `registry.altlinux.org` to the system's `containers-storage:` and then places them in the directory specified by the first parameter in the subdirectory with the architecture name `$ociDir/$arch`. To improve subsequent compression, image layers are placed uncompressed (parameter `--dest-oci-accept-uncompressed-layers`)

- After the architecture subdirectory is filled, it is archived, compressed and placed in the file `$ociDir/$arch.tar.xz`

## EXAMPLES

`podsec-save-oci /tmp/ociDir/ amd64,arm64 k8s-c10f1/flannel:v0.19.2 k8s-c10f1/flannel-cni-plugin:v1.2.0`

## SECURITY CONSIDERATIONS

- Since the script loads images of different architectures, the last one loaded into containers-storage: architecture may differ from the current processor architecture. If necessary, you will need to reload the images for the working processor architecture

## AUTHOR

Kostarev Alexey, Basealt LLC
kaf@basealt.ru
