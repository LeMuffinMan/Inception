#!/usr/bin/env bash
# Usage: sudo ./edit_hosts.sh <hostname>
# Example: sudo ./edit_hosts.sh myserver.local

set -euo pipefail

HOSTS_FILE="/etc/hosts"
HOST="${1:-}"

# --- Argument validation ---
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

# --- Hosts file checks ---
if [[ ! -e "$HOSTS_FILE" ]]; then
    echo "Error: '${HOSTS_FILE}' does not exist." >&2
    exit 1
fi

if [[ ! -f "$HOSTS_FILE" ]]; then
    echo "Error: '${HOSTS_FILE}' is not a regular file." >&2
    exit 1
fi

if [[ ! -r "$HOSTS_FILE" || ! -w "$HOSTS_FILE" ]]; then
    echo "Error: insufficient permissions on '${HOSTS_FILE}'. Try running with sudo." >&2
    exit 1
fi

# --- Backup ---
BACKUP="${HOSTS_FILE}.bak.$(date +%Y%m%d%H%M%S)"
cp --preserve=mode,ownership "$HOSTS_FILE" "$BACKUP"
echo "Backup created: ${BACKUP}"

# --- Atomic edit via temp file ---
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

# Comment out all active 127.0.0.1 lines (tab or space as separator)
sed -E 's|^(127\.0\.0\.1[[:blank:]]+.*)$|#\1|' "$HOSTS_FILE" > "$TMPFILE"

# Check if any active 127.0.0.1 entry remains
if ! grep -qE '^127\.0\.0\.1[[:blank:]]' "$TMPFILE"; then
    # Prepend the new entry at the top of the file
    { echo -e "127.0.0.1\t${HOST}"; cat "$TMPFILE"; } > "${TMPFILE}.new"
    mv "${TMPFILE}.new" "$TMPFILE"
    echo "No active 127.0.0.1 entry found — added '127.0.0.1 ${HOST}' at the top."
else
    echo "Active 127.0.0.1 entries still present, nothing was added."
fi

# Atomically replace the hosts file
cp --preserve=mode,ownership "$TMPFILE" "$HOSTS_FILE"

echo "Done. Current state of ${HOSTS_FILE}:"
cat -n "$HOSTS_FILE"
