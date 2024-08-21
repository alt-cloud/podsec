podsec-inotify-build-invulnerable-image(1) -- скрипт создания docker-образов и проверки их сканером безопасности trivy
================================

## SYNOPSIS

`podsec-inotify-build-invulnerable-image <имя_образа> [ <docker_файл> [ <каталог_контекста> [ <параметры_podman_build>`

## DESCRIPTION

Для корректной работы скрипта необходимо запустить сервис `trivy`:
```
systemctl enable --now trivy
```

Скрипт производит создание docker-образа `имя_образа`, описанного в `docker_файл` (по умолчанию `Dockerfile`) в каталоге `каталог_контекста` (по умолчанию текущий) с параметрами сборки `параметры_podman_build`.

После создание образа он проверяется на наличие уязвимостей сервисом `trivy`.


## EXAMPLES

`podsec-inotify-build-invulnerable-image my-first-image`

## SEE ALSO

[The all-in-one open source security scanner](https://trivy.dev/)


## AUTHOR

Костарев Алексей, Базальт СПО
kaf@basealt.ru
