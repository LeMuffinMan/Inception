#!/bin/bash

set -euo pipefail

HOSTS_FILE="/etc/hosts"
HOST="${1:-}"

if [[ -z "$HOST" ]]; then
    echo "Error: no hostname provided." >&2
    echo "Usage: sudo $0 <hostname>" >&2
    exit 1
fi

# Allow only valid hostname characters (RFC 1123 + dots)
if [[ ! "$HOST" =~ ^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,252}[a-zA-Z0-9])?$ ]]; then
    echo "Error: invalid hostname '${HOST}'." >&2
    exit 1
fi

if [[ ! -e "$HOSTS_FILE" ]]; then
    echo "Error: '${HOSTS_FILE}' does not exist." >&2
    exit 1
fi

if [[ ! -f "$HOSTS_FILE" ]]; then
    echo "Error: '${HOSTS_FILE}' is not a regular file." >&2
    exit 1
fi

LINE_TO_EDIT=$(grep "^127.0.0.1" /etc/hosts)
if echo "$LINE_TO_EDIT" | grep -q "$HOST"; then
    echo "/etc/hosts already edit to redirect localhost to $HOST"
else
    BACKUP="${HOSTS_FILE}.bak.$(date +%Y%m%d%H%M%S)"
    cp --preserve=mode,ownership "$HOSTS_FILE" "$BACKUP"
    echo "/etc/hosts backup created: ${BACKUP}"

    # Atomic edit via temp file
    TMPFILE=$(mktemp)
    #we clean automatically this tmp file in any case, using trap: at end of execution, in case of crash or not, we rm -rf it
    trap 'rm -f "$TMPFILE"' EXIT

    sed -E 's|^(127\.0\.0\.1[[:blank:]]+.*)$|#\1|' "$HOSTS_FILE" > "$TMPFILE"

    # Atomically replace the hosts file
    cp --preserve=mode,ownership "$TMPFILE" "$HOSTS_FILE" && echo "/etc/hosts successfully updated with 127.0.0.1 $HOST" || echo "Failed to edit /etc/hosts to redirect on $HOST"
fi
