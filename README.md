# PODSEC (Podman Security)

`podsec` - a set of scripts for deploying and supporting secure `rootless` solutions for `podman` and `rootless-kubernetes` (`podsec-u7s`) within the `c10+`, `p10+` `ALTLinux` distributions.


Provides:

1. Deploying a `rootfull` or `rootless` `kubernetes` cluster version `v1.26.3` and higher

2. Creating users of different categories with different rights to access and work with docker images.

3. Creation of an image `docker registry` and a `WEB serve`r for access to image signatures.

4. Setting up access policies and working with images for several categories of users.

5. Providing users access to the kubernetes cluster.

6. Configuring RBAC access rules to the kubernetes cluster.

For step by step migration from `rootfull` clusters it is possible to deploy heterogeneous clusters by connecting `rootless` nodes to a `rootfull` cluster.
In this case, there is no need to use the other features (2-6).

Installation and configuration details are described on the [Rootless kubernetes](https://www.altlinux.org/Rootless_kubernetes) page.

## User categories

Users are divided into the following categories:

- Administrators - users belonging to the `whell` group including root.

- The `rootless kubernetes` administrator is `u7s-admin`.

- Creators of `docker images`

- Users of `docker images`

### Administrators

This user category has the right to create *creator* users and *docker image users*.

In addition, when creating a kubernetes cluster, they have the right to administer the cluster.

### Rootless kubernetes administrator - u7s-admin

This user belongs to system users.
Not belong to the `wheel` group. From the point of view of the host system, he is an ordinary (non-privileged) user.
All `Pods` in the `rootless kubernetes cluster` are launched on his behalf (under his `uid`) and within his `namespace`.

Like the `Administrator`, he has the right to administer the `rootless` `kubernetes cluster`.
But unlike it, it allows you to enter its `namespace` and administer the resources of this `namespace` within the node:
- network interfaces `tap0`, `cni0`, ...;
- `iptables` rules;
- files and directories created within this `namespace`;
- processes;
- ...

In addition, it allows you to view the logs of the node's Pods in the directory `/var/log/pods/...`


### Docker image creators

Users in this category have all rights to work with images:

- Download images from any available registrar.

- Import/Export of images from archive formats.

- Creating images from `Dockefile`'s.

- Placing images on recorders.

- Placing your images with your electronic signature on the local registrar `registry.local`

Users belong to the groups `podman-dev`, `podman`.

### Docker image users

Users in this category do not have any of the above rights to work with images, with the exception of downloading signed images from the local registry `registry.local` and working with them.

Users belong to `podman` groups.

## A set of RPM packages

The specification file `podsec.spec` provides the creation of the following `RPM packages`:

- `podsec` - a set of scripts for creating `users`, `access policies`, deploying a `local registry and `WEB signature server`, loading an archive of kubernetes images into the `local registry`.

- `podsec-k8s` - a set of scripts for deploying a rootless `kubernetes` cluster

- `podsec-k8s-rbac` - a set of scripts for providing users with access to the `kubernetes cluster` and assigning them roles within the cluster.

- `podsec-inotify` - a set of scripts for monitoring violations of security policies.

- `podsec-dev` - a set of scripts for installing and updating `kubernetes images`.



## Notes

- `podsec*` packages work under `Linux kernel` version `5.15` and higher.
