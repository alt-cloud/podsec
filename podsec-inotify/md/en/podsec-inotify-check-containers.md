podsec-inotify-check-containers(1) -- check for changes in critical files of rootfull and rootless containers
=================================

## SYNOPSIS

`podsec-inotify-check-containers`

## DESCRIPTION

Script:

- creates a list of `rootless` and `rootfull` container directories existing in the system,

- runs a check for addition, deletion, and modification of files in container directories,

- sends a notification about the change to the system log.

The script starts two directory monitoring processes:

- monitoring of adding users in the `/home/` directory, adding containers in the `*/storage/overlay/` `rootless` and `rootfull` user directories (the list is generated in the `/tmp/inotifyMonitor.tmp` file);

- monitoring of file changes in the `rootless` and `rootfull` user containers (the list is generated in the `/tmp/inotifyOverlays.tmp` file).

When the monitored directories change, the first process generates lists in the `/tmp/inotifyMonitor.tmp`, `/tmp/inotifyOverlays.tmp` monitoring files, restarts itself and the second process of monitoring file changes in containers.

The second process of changing files in containers monitors all files and directories except for files and directories
in the root directories `/var/`, `/proc/`, `/tmp/`, `/run/`,
which can be intensively changed when containers are running by container services.

Changes in the directories `/home/`, `/root/`, `/etc/` are logged to the system log as warnings (level `Warning`).
Changes in other directories are logged to the system log as critical (level `Critical`).

Messages in the system log have the following format:
```
An event <event> occurred in the container <container> [in home directory|in configuration directory] on the file <file>
```

## SECURITY CONSIDERATIONS

- This script is run by the service `podsec-inotify-check-containers.service`.

## EXAMPLES

If containers are deployed in the system and you need to monitor file modifications inside these containers, run the service `podsec-inotify-check-containers.service`:
```
# systemctl enable --now podsec-inotify-check-containers.service
```

## AUTHOR

- Burykin Nikolay, ALT Linux Team, bne@altlinux.org
- Kostarev Alexey, ALT Linux Team, kaf@basealt.ru
