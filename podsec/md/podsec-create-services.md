podsec-create-services(1) -- создание сервисов для поддержки регистратора докер образов и сервера подписей образов
================================

## SYNOPSIS

`podsec-create-services`

## DESCRIPTION

Скрипт поднимает сервисы `docker-registry` и `nginx` для поддержки регистратора докер образов и сервера подписей образов.

- регистратор образов принимает запросы по адресу `http://registry.local` и хранит образы в каталоге `/var/lib/containers/storage/volumes/registry/_data/`;

- сервис подписей образов принимает запросы по адресу `http://sigstore.local:81`, хранит подписи образов в каталоге `/var/sigstore/sigstore/`, открытые ключи в каталоге `/var/sigstore/keys/`


## SECURITY CONSIDERATIONS

Данный скрипт должен запускаться только на узле с доменами `registry.local`, `sigstore-local`, где располагаются пользователи создающие и подписывающие образы. Если это не так, скрипт прекращает свою работу не запуская сервисы.

## SEE ALSO

- [Описание периодического контроля целостности образов контейнеров и параметров настройки средства контейнеризации](https://github.com/alt-cloud/podsec/tree/master/ImageSignatureVerification)

## AUTHOR

Костарев Алексей, Базальт СПО
kaf@basealt.ru
