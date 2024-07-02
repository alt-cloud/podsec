s/^.*[[:space:]]*\(podsec-.*\)\[[0-9]\+\]:[[:space:]]*\(Crash\|Fatal\|Critical\|High\|Middle\):[[:space:]]\(.*\)$/podsec:CRITICAL:\1(\2) \3/p
s/^.*[[:space:]]\(podsec-.*\)\[[0-9]\+\]:[[:space:]]*\(Warning\):[[:space:]]\(.*\)$/podsec:WARNING:\1(\2) \3/p
