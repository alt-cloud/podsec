podsec-nagios-plugins-create-nagiosuser(1) -- создание пользователя nagios от имени которого запускаются nagios плугины
================================

## SYNOPSIS

`podsec-nagios-plugins-create-nagiosuser`

## DESCRIPTION

Создание пользователя nagios от имени которого запускаются nagios плугины.

## OPTIONS

## EXAMPLES

`podsec-nagios-plugins-create-nagiosuse`

## SECURITY CONSIDERATIONS

- После создания пользователя необходимо для беспарольного доступа со стороны сервера передать открытый ключ командой
  `ssh-copy-id`.

- Пользователь `nagios` входят в группу `wheel` и имеет возможноть запускать программы от имени `root`. Необходимо очень тщательно защищать пароль и закрытый ключ аналогичного пользвателя `nagios` на сервере, который имеет право запускать скрипты от своего имени на клиентской машине.

## SEE ALSO


## AUTHOR

Костарев Алексей, Базальт СПО
kaf@basealt.ru
