s/^.*[[:space:]]\(Crash\|Fatal\|Critical\|High\|Middle\)\[[0-9]\+\]:[[:space:]]*\(podsec-.*\):[[:space:]]\(.*\)$/podsec:CRITICAL:\2(\1) \3/p
s/^.*[[:space:]]\(Warning\)\[[0-9]\+\]:[[:space:]]*\(podsec-.*\):[[:space:]]\(.*\)$/podsec:WARNING:\2(\1) \3/p

