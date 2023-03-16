
podsec-load-sign-oci - скрипт извлекает из oci-архива образы, разворачивает их в файловой системе, подписывает и помещает на регистратор

## SYNOPSIS

podsec-load-sign-oci <имя_архивного_файла> <архитектура> <имя_регистратора> <EMail_подписанта>

## DESCRIPTION

Скрипт:
- извлекает из сжатого  xz-oci-архива образы,
- разворачивает их в файловой системе,
- подписывает и помещает на регистратор.

## EXAMPLES

# podsec-load-sign-oci /mnt/cdrom/containers/amd64.tar.xz amd64 registry.local/k8s-p10 kaf@baseat.ru
