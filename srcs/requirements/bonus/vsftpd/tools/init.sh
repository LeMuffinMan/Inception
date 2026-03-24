#!/bin/bash

set -e

FTP_USER=$(cat /run/secrets/ftp_user)
FTP_PASS=$(cat /run/secrets/ftp_pass)

if ! id $FTP_USER  > /dev/null; then
    echo "Setting FTP_USER ..."
    adduser -D -h "/home/$FTP_USER" "$FTP_USER"
    echo "$FTP_USER:$FTP_PASSWORD" | chpasswd
else
    echo "vsftpd is alrady configured"
fi

mkdir -p /var/run/vsftpd/empty
#chown le repertoire ?

echo "Starting vsftpd ..."
exec vsftpd /etc/vsftd/vsftpd.conf || echo "Failed to start vsftpd"
