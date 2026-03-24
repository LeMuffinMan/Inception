#!/bin/sh

HOSTS_FILE="/etc/hosts"
BACKUP_FILE="/etc/hosts.bak"

if [ ! -f "$BACKUP_FILE" ]; then
  sudo cp "$HOSTS_FILE" "$BACKUP_FILE"
fi

#Since /etc/hosts is sensitive file, we want to edit it securly, using a tmp:
# - if our script crash, /etc/hosts is not edited
# - in any case, we created a backup to undo manualy
tmp=$(mktemp)

awk '
# Décommente exactement la ligne voulue
$0 == "127.0.0.1\tlocalhost" {
    print "#127.0.0.1\tlocalhost"
    next
}

# Supprime toutes les autres lignes en 127.0.0.1
$0 ~ /^127\.0\.0\.1/ {
    print "127.0.0.1\t$DOMAIN"
    next
}

# Garde le reste
{
    print
}
' "$HOSTS_FILE" > "$tmp"

# doing so, we do an atomic replacement : the file is replaced in one operation, not open and edit char by char
# it prevent corruption risk for such sensitive file
sudo mv "$tmp" "$HOSTS_FILE"
