#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

fake_rootlessctl="$tmpdir/rootlessctl"
calls="$tmpdir/rootlessctl.calls"
conf="$tmpdir/rootlesskit-ports.conf"
socket="$tmpdir/api.sock"

cat >"$fake_rootlessctl" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$U7S_ROOTLESSCTL_CALLS"
EOF
chmod +x "$fake_rootlessctl"

cat >"$conf" <<'EOF'
# persistent rootlesskit ports

0.0.0.0:30443:30443/tcp
  127.0.0.1:18080:8080/tcp
EOF

export U7S_ROOTLESSCTL="$fake_rootlessctl"
export U7S_ROOTLESSCTL_CALLS="$calls"

source "$repo_root/usernetes/bin/rootlesskit-ports"

u7s_rootlesskit_add_ports_from_file "$conf" "$socket"

expected="--socket $socket add-ports 0.0.0.0:30443:30443/tcp
--socket $socket add-ports 127.0.0.1:18080:8080/tcp"
actual="$(cat "$calls")"

if [[ "$actual" != "$expected" ]]; then
	printf 'unexpected rootlessctl calls\nexpected:\n%s\nactual:\n%s\n' "$expected" "$actual" >&2
	exit 1
fi
