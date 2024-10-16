podsec-inotify-check-policy(1) -- The plugin checks the containerization policy settings on the node
=================================

## SYNOPSIS

`podsec-inotify-check-policy [-v[vv]] [-a interval] [-f interval] -c interval -h interval [-m interval] -w intervalъ [-l interval] [-d interval] [-M EMail]`

## DESCRIPTION

### General description

The plugin checks the containerization policy settings on the node.

The check is based on the following parameters:

- file `policy.json` settings of transports and access policies to registrars:
<pre>
User Control Parameter | Metric Weight
-----------------------------------------------------------------------------------------------------------------------------|-------------
having `defaultPolicy != reject`, but not included in the `podman_dev` group                                                 | 102
not having `registry.local` in the list of registrars for which the presence of an electronic signature of images is checked | 103
having registrars in the policy for which the presence of an electronic signature of images is not checked                   | 104
having transports other than `docker` in the list of supported ones (transport for receiving images from the registrar)      | 105
</pre>

- files for binding registrars to servers storing electronic signatures (default binding file `default.yaml` and registrar binding files `*.yaml` of the `registries.d` directory). Availability (number) of users:
<pre>
User Control Parameter                                                                    | Metric Weight
------------------------------------------------------------------------------------------|-------------
not using signature store `http://sigstore.local:81/sigstore/` as default signature store | 106
</pre>

- user group control

    * presence of users with images, but not included in the `podman` group:
<pre>
User control parameter | Metric weight
----------------------------------------------------------------------|-------------
presence of users with images, but not included in the `podman` group | 101
</pre>

    * presence of users of the `podman` group (excluding those in the `podman_dev` group):
<pre>
User control parameter | Metric weight
-----------------------------------------------------------------------------|-------------
in the `wheel` group                                                         | 107
having the `.config/containers/` directory open for writing and modification | 90 * `share_of_offenders`
not having the `.config/containers/storage.conf` configuration file          | 90 * `share_of_offenders
</pre>

`share_of_violators` is calculated as: `number_of_violators / number_of_users_in_podman_group`

All metric weights are summed up and a final metric is formed.

## OPTIONS

When the `-M Email` flag is specified, the final message is sent to the specified user.

The danger level is determined at startup by the flags:

- for system logs:
<pre>
Level name |Level| Prefix   | Flag | Recommended interval value
-----------|-----|----------|------|---------------------------
emergency  | 7   | Crash    | `-a` | do not specify
fatal      | 6   | Fatal    | `-f` | do not specify
critical   | 5   | Critical | `-c` | 100
high       | 4   | Heigh    | `-h` | 0
average    | 3   | Middle   | `-m` | do not specify
Low        | 2   | Low      | `-l` | do not specify
Debug      | 1   | Debug    | `-d` | do not specify
</pre>

- for the `icigna` server:
<pre>
Level name |Level|  Prefix  | Flag | Recommended interval value
-----------|-----|----------|------|----------------------------
Critical   | 2   | Critical | `-c` | 100
Warning    | 1   | Warning  | `-w` | 0
</pre>

Any parameter may be missing. In this case, it is not considered when viewing the compliance of the received metric with the intervals.

The parameter values ​​have the interval format described in the nagios documentation: [Threshold and Ranges](https://nagios-plugins.org/doc/guidelines.html#THRESHOLDFORMAT).

General description:

`[@]start:end`

Notes:

* `start` ≤ `end`
* `start` and `:` are not required if `start=0`
* if the interval is specified in the format `start:` and the end is not specified, then the end of the interval is considered to be infinity `ꝏ`
* to indicate negative infinity (`-ꝏ`) use `~`
* the trigger fires when the metric value is **OUTSIDE THE SPECIFIED INTERVAL** (**start and end points are included in the interval**)
* if the interval begins with the `@` symbol, then the condition is inverted - the trigger fires when the metric value is **IN THE SPECIFIED INTERVAL** (start and end points are included in the interval)

Examples of possible formats:
<pre>
Interval format | Description of the trigger condition
----------------|--------------------------------------
100             | metrica &lt; 0 || metrica &gt; 100 (outside the range 0-100)
100:            | metrica &lt; 100 (outside the range 100-ꝏ)
~:100           | metrica &gt; 100 (outside the range -ꝏ-100)
20-100          | metrica &lt; 20 || metrica &gt; 100 (outside the range 20-100)
@20-100         | metrica &gt;= 20 && metrica &lt;= 100 (in the range 20-100)
</pre>

### System logs

For system logs, the danger level is determined for each message.
The danger level intervals specified by the parameters are viewed in order from highest to lowest.
The message level is determined by the first match found (remember that the trigger is triggered when the metric is OUTSIDE the interval).
If no match is found, the message is not output to the system log.

Based on the level found, the priority of the message and its tag (prefix) are determined.
A message with the specified priority and tag is sent to the system log using the logger command:
<pre>
# logger -p priority -t tag "tag: message"
</pre>

In addition to the main message for `icigna`, the following are generated:

- a list of offending users;
- shortened messages for detail level `1`.


### icigna logs

The formats of messages and exit codes of the plugin are described in [Plugin Output for Nagios](https://nagios-plugins.org/doc/guidelines.html#PLUGOUTPUT).

The severity level for icigna logs is determined by the TOTAL metric.
The total metric is determined to determine the level and compared with the intervals specified by the flags

* `-c` - `Critical`
* `-w` - `Warning`

If no match is found, `icigna` prints the message:
<pre>
POLICY OK: Containerization policies are not violated
</pre>
The program exit code (which is processed on the `icigna` server side) is `0`.

The log format for `icigna` depends on the level of detail specified by the `-v[vv]` flag (see [Verbose Output](https://nagios-plugins.org/doc/guidelines.html#AEN41)):
<pre>
Flag | Level
-----|--------
none | 0
-v   | 1
-vv  | 2
-vvv | 3
...  | 3
</pre>

For all levels, a prefix message of the following format is generated:
<pre>
POLICY $prefix:
</pre>
Where `prefix` takes the following values ​​depending on the severity level:

- `-c` - `Critical`
- `-w` - `Warning`

If the level of detail is `0`, a shortened message is output.
<pre>
POLICY $prefix: Violation of user containerization policies <users>
</pre>
Where `users` is a list of users for whom violations were detected.

If the detail level is `1`, then the first detail level from the list of shortened messages generated during the formation of system logs is added to the message with the prefix *There are users:*.

<pre>
POLICY $prefix: Violation of user containerization policies $users | There are users:
shortened message
...
</pre>

If the detail level is `2`, then the second detail level from the list of full messages generated during the formation of system logs is added to the message.
<pre>
POLICY $prefix: Violation of user containerization policies $users | There are users:
shortened message
...
shortened message |
full message
...
</pre>

After displaying messages, the plugin exits with the exit code:

- `Critical` - `2`
- `Warning` - `1`

### Starting a service via systemd/Timers

In addition to starting the script via `nagios`, the script can be started via `systemd/Timers`.
The package includes the systemd files `podsec-inotify-check-policy.service`, `podsec-inotify-check-policy.timer`.
The service file `podsec-inotify-check-policy.service` describes a line in the `ExecStart` parameter describing the startup mode of the `podsec-inotify-check-policy` script.
The script is started with the flags `-vvv -c 100` - display detailed information, all messages have the `c` level - critical.
If incorrect policy settings are detected during the script's operation, they are output to the system log and sent by mail to the system administrator (`root`).

The schedule for starting the service `podsec-inotify-check-policy.service` is described in the `OnCalendar` parameter of the schedule file `podsec-inotify-check-policy.timer`.
The service is called every hour.

By default, the service start timer is disabled. To enable it, enter the command:
<pre>
# systemctl enable --now podsec-inotify-check-policy.timer
</pre>
If you need to change the script startup mode, edit the `OnCalendar` parameter of the schedule file `podsec-inotify-check-policy.timer`.

## EXAMPLES

Analyze policy policies with maximum detail.
Critical level (`nagios`, `system`) `>100`. Warning level (`nagios`) `>0`. Low level (`system`) `>0`.
<pre>
# podsec-inotify-check-policy -vvv -w 0 -h 0 -c 100
POLICY Critical(18): Violation of containerization policies for users "imagedeveloper" "k8s-user1" "kaf" "kafpodman" "podmanuser" "root" "securityadmin" "user" "user1" | There are users:
outside the podman group,
able to receive any image
able to receive a local image without a signature
able to receive any image without a signature
able to receive any image via a prohibited transport
not using a local signature keeper
included in the wheel group
not having a configuration file
able to change the configuration" |
Critical(101): Users "kafpodman" have images, but are not in the 'podman' group
Critical(102): Users "user" have defaultPolicy!=reject in policy.json, but are not in the 'podman_dev' group
Critical(103): Users "user" do not have registry.local in the list of registrars for which the presence of an electronic signature of images is checked
Critical(104): Users "root" "kaf" "kafpodman" "podmanuser" "securityadmin" "user1" have registrars in the policy for which the presence of an electronic signature of images is not checked
Critical(105): Users "user" have transports other than docker in the supported list
Critical(106): Users "imagedeveloper" "user" do not use signature store http://sigstore.local:81/sigstore/ as default signature store
Critical(107): Users "kaf" "securityadmin" are members of groups 'podman' and 'wheel'
High(72): Users "k8s-user1" "kaf" "securityadmin" "user1" do not have a .config/containers/storage.conf configuration file
High(18): Users "user" have a writable .config/containers configuration directory
</pre>

Program exit code is `2`.

## SECURITY CONSIDERATIONS

## SEE ALSO

- [Nagios Plugins. Development Guidelines](https://nagios-plugins.org/doc/guidelines.html#PLUGOUTPUT)

## AUTHOR

Kostarev Alexey, Basealt LLC
kaf@basealt.ru
