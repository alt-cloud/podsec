s/^.*[[:space:]]*\(podsec-inotify-check-.*\)\[[0-9]\+\]:[[:space:]]*\(Crash\|Fatal\|Critical\|High\|Middle\):[[:space:]]\(.*\)$/\1:CRITICAL:\1(\2) \3/p
s/^.*[[:space:]]\(podsec-inotify-check-.*\)\[[0-9]\+\]:[[:space:]]*\(Warning\):[[:space:]]\(.*\)$/\1:WARNING:\1(\2) \3/p
