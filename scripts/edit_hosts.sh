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

if grep -qE "^127\.0\.0\.1[[:blank:]]+${HOST}([[:blank:]]|$)" "$HOSTS_FILE"; then
    echo "/etc/hosts already redirects 127.0.0.1 to ${HOST}"
else
    # BACKUP="${HOSTS_FILE}.bak.$(date +%Y%m%d%H%M%S)"
    # cp --preserve=mode,ownership "$HOSTS_FILE" "$BACKUP"
    # echo "/etc/hosts backup created: ${BACKUP}"

    TMPFILE=$(mktemp)
    trap 'rm -f "$TMPFILE" "${TMPFILE}.new"' EXIT

    sed -E 's|^(127\.0\.0\.1[[:blank:]]+.*)$|#\1|' "$HOSTS_FILE" > "$TMPFILE"

    { printf '127.0.0.1\t%s\n' "$HOST"; cat "$TMPFILE"; } > "${TMPFILE}.new"

    if cp --preserve=mode,ownership "${TMPFILE}.new" "$HOSTS_FILE"; then
        echo "/etc/hosts successfully updated: 127.0.0.1 ${HOST}"
    else
        echo "Error: failed to update /etc/hosts." >&2
        exit 1
    fi
fi
