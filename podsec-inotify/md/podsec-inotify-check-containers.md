podsec-inotify-overlays(1) -- проверка наличия изменений файлов в директориях rootless контейнерах
================================

## SYNOPSIS

`podsec-inotify-overlays`

## DESCRIPTION

Скрипт:

- создаёт список директорий rootless контейнеров, существующих в системе,

- запускает проверку на добавление,удаление, и изменение файлов в директориях контейнеров,

- отсылает уведомление об изменении в системный лог.


## SECURITY CONSIDERATIONS

- Данный скрипт запускается сервисом inotify-overlays.service. 

## EXAMPLES

Если в системе развернуты контейнеры, и требуется следить за модификацией файлов внутри этих контейнеров, запустите сервис inotify-overlays.service:
```
# systemctl enable --now inotify-overlays.service
```
По умолчанию в системный лог отсылаются сообщения двух типов: CRITICAL и INFO.
Для отключения логгирования событий типа INFO замените в скрипте /usr/bin/podsec-inotify-overlays значение переменной INFO_LOG с YES на NO.

## AUTHOR

Burykin Nikolay, ALT Linux Team,
bne@altlinux.org
