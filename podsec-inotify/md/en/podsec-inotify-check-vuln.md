podsec-inotify-check-vuln(1) -- script for monitoring docker images of the node with the trivy security scanner
=================================

## SYNOPSIS

`podsec-inotify-check-vuln [-m EMail]`

## DESCRIPTION

For the script to work correctly, the `trivy` service must be started:
```
systemctl enable --now trivy
```

The script monitors `docker images` of the node with the `trivy` security scanner:

- If the script is run as the `root` user, the script:

* checks `rootfull` images with the `trivy` scanner;

* for all users of the `/home/` directory, the presence of `rootless` images is checked. If they are present, the `trivy` scanner checks these images.

- If the script is run as a regular user, it checks for `rootless` images. If they are present, it scans these images with the `trivy` scanner.

The analysis result is sent to the system log.
If the `-m` flag is present, if the number of `HIGH` threats detected during image analysis is greater than 0, the result is sent by mail to the system administrator (`root`).

## OPTIONS

If the `-m EMail` flag is specified, if there are vulnerabilities of the 'HIGH' level, a message is sent to the specified user.

In addition to this script, the package includes:

- The `podsec-inotify-check-vuln.service` service file describes in the `ExecStart` parameter a line describing the launch mode of the `podsec-inotify-check-vuln` script for detecting vulnerabilities, writing them to the system log and sending them by mail to the system administrator.

- The schedule file `podsec-inotify-check-vuln.timer`, which specifies the schedule for starting the service `podsec-inotify-check-vuln.service` in the `OnCalendar` parameter. The service is called every hour.

By default, the service start timer is disabled. To enable it, enter the command:
<pre>
# systemctl enable --now podsec-inotify-check-vuln.timer
</pre>
If you need to change the script startup mode, edit the `OnCalendar` parameter of the schedule file `podsec-inotify-check-vuln.timer`.

## EXAMPLES

`podsec-inotify-check-vuln`

## SECURITY CONSIDERATIONS

-

## SEE ALSO

[The all-in-one open source security scanner](https://trivy.dev/)

## AUTHOR

Aleksey Kostarev, Basealt LLC
kaf@basealt.ru
