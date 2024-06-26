s/^.*[[:space:]]\(podsec-.*\):\(Warning\)\[[0-9]\+\]:[[:space:]]*\(.*\)$/\1: WARNING: \3/p
s/^.*[[:space:]]\(podsec-.*\):\(Crash\|Fatal\|Critical\|High\|Middle\)\[[0-9]\+\]:[[:space:]]*\(.*\)$/\1: CRITICAL: \3/p
