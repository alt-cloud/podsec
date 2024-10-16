podsec-inotify-check-images(1) -- The plugin checks images for compliance with the containerization policies on the node
===================================
## SYNOPSIS

`podsec-inotify-check-images [-v[vv]] [-a interval] [-f interval] -c interval -h interval [-m interval] х-w intervalъ [-l interval] [-d interval] [-M EMail]`

## DESCRIPTION

The plugin checks images for compliance with the containerization policies on the node.
The check is based on the following parameters:

User control parameter | Metric weight
-----------------------------------------------------------------------------------|-------------
presence of registrars in the user policy that do not support electronic signature | 101
presence of unsigned images in the image cache | 102
presence of images in the cache outside the supported policies | 103

All metric weights are summed up and a final metric is formed.

## OPTIONS

If the `-M Email` flag is specified, the final message is sent to the specified user.

The danger level is determined at startup by the flags:

- for system logs:
<pre>
Level name |Level| Prefix   | Flag | Recommended interval value
-----------|-----|----------|------|---------------------------
emergency  | 7   | Crash    | `-a` | do not specify
fatal      | 6   | Fatal    | `-f` | do not specify
critical   | 5   | Critical | `-c` | 100
high       | 4   | Heigh    | `-h` | 0
medium     | 3   | Middle   | `-m` | do not specify
low        | 2   | Low      | `-l` | do not specify
debug      | 1   | Debug    | `-d` | do not specify
</pre>

- for the `icigna` server:
<pre>
Level name |Level| Prefix   | Flag | Recommended interval value
-----------|----------------|------|---------------------------
critical   |  2  | Critical | `-c` | 100
warning    |  1  | Warning  | `-w` | 0
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

The log format for `nagios` depends on the level of detail specified by the `-v[vv]` flag (see [Verbose Output](https://nagios-plugins.org/doc/guidelines.html#AEN41)):
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

### Starting the service via systemd/Timers

In addition to running the script via `nagios`, the script can be run via `systemd/Timers`.

The package includes the systemd files `podsec-inotify-check-images.service`, `podsec-inotify-check-images.timer`.
The service file `podsec-inotify-check-images.service` describes a line in the `ExecStart` parameter describing the startup mode of the `podsec-inotify-check-images` script.
The script is run with the flags `-vvv -c 100` - display detailed information, all messages have a level of `c` - critical.
If incorrect policy settings are detected during the script's operation, they are written to the system log and sent by mail to the system administrator (`root`).

The schedule for starting the `podsec-inotify-check-images.service` service is described in the `OnCalendar` parameter of the `podsec-inotify-check-images.timer` schedule file.
The service is called every hour.

By default, the service start timer is disabled. To enable it, enter the command:
<pre>
# systemctl enable --now podsec-inotify-check-images.timer
</pre>
If you need to change the script startup mode, edit the `OnCalendar` parameter of the `podsec-inotify-check-images.timer` schedule file.

## EXAMPLES

`podsec-inotify-check-images -vvv  -w 0 -h 0 -c 100`

## SECURITY CONSIDERATIONS


## SEE ALSO


## AUTHOR

Kostarev Alexey, Basalt LLC
kaf@basealt.ru
