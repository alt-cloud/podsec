podsec-inotify-build-invulnerable-image(1) -- script for creating docker images and checking them with the trivy security scanner
==================================

## SYNOPSIS

`podsec-inotify-build-invulnerable-image <image_name> [ <docker_file> [ <context_directory> [ <podman_build_parameters>`

## DESCRIPTION

For the script to work correctly, you need to run the `trivy` service:
```
systemctl enable --now trivy
```

The script creates a docker image `image_name`, described in `docker_file` (by default `Dockerfile`) in the `context_directory` directory (by default, the current one) with the build parameters `podman_build_parameters`.

After the image is created, it is checked for vulnerabilities by the `trivy` service.

## EXAMPLES

`podsec-inotify-build-invulnerable-image my-first-image`

## SEE ALSO

[The all-in-one open source security scanner](https://trivy.dev/)

## AUTHOR

Aleksey Kostarev, Basealt LLC
kaf@basealt.ru
