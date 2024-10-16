podsec-k8s-save-oci(1) -- archiving kubernetes images version 1.26.3 of different architectures to the directory specified by the first parameter, followed by compression and formation of `xz-oci-archive`
==================================

## SYNOPSIS

`podsec-save-oci image_archiving_directory architecture,architecture,...|all image ...`

## DESCRIPTION

- The script archives images to the directory specified by the first parameter

- The second parameter specifies the architectures to be archived, separated by commas. If the second parameter is all, all architectures are archived: `amd64`, `arm64`, `arm ppc64le`, `386`.

- The script downloads the images
`k8s-c10f1/coredns:v1.9.3`, `k8s-c10f1/kube-controller-manager:v1.26.3`, `k8s-c10f1/kube-apiserver:v1.26.3`, `k8s-c10f1/kube-proxy:v1.26.3`, `k8s-c10f1/etcd:3.5.6-0`, `k8s-c10f1/flannel:v0.19.2`, `k8s-c10f1/kube-scheduler:v1.26.3`, `k8s-c10f1/pause:3.9`, `k8s-c10f1/flannel-cni-plugin:v1.2.0`, `k8s-c10f1/cert-manager-controller:v1.9.1`, `k8s-c10f1/cert-manager-cainjector:v1.9.1`, `k8s-c10f1/cert-manager-webhook:v1.9.1`
from the registrar `registry.altlinux.org` to the system's `containers-storage:` and then placing them in the directory specified by the first parameter in a subdirectory with the architecture name `$ociDir/$arch`. To improve subsequent compression, image layers are placed uncompressed (parameter `--dest-oci-accept-uncompressed-layers`)

- After the architecture subdirectory is filled, it is archived, compressed and placed in the file `$ociDir/$arch.tar.xz`

## EXAMPLES

`podsec-k8s-save-oci /tmp/ociDir/ amd64,arm64`

## SECURITY CONSIDERATIONS

- Since the script loads images of different architectures, the last one loaded into containers-storage: architecture may differ from the current processor architecture. If necessary, you will need to reload the images for the working processor architecture

## SEE ALSO

## AUTHOR

Aleksey Kostarev, Basealt LLC
kaf@basealt.ru
