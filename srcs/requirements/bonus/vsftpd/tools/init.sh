#!/bin/bash

set -e

FTP_PASS=$(cat /run/secrets/ftp_pass)

if ! id $FTP_USER  > /dev/null 2>&1; then
    echo "Setting FTP_USER ..."
    useradd -m -d /var/log/vsftpd $FTP_USER
    echo "$FTP_USER:$FTP_PASS" | chpasswd
    chown -R $FTP_USER:$FTP_USER /var/www/html

    mkdir -p /var/log/vsftpd/
    chown -R $FTP_USER:$FTP_USER /var/log/vsftpd/
    mkdir -p /var/empty
    chown -R $FTP_USER:$FTP_USER /var/empty
else
    echo "vsftpd is already configured"
fi

exec /usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf
