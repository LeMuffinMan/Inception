#!/bin/sh

set -e

FTP_USER=$(cat /run/secrets/ftp_user)
FTP_PASS=$(cat /run/secrets/ftp_pass)

useradd -m -d "$FTP_USER" || echo "Failed to create $FTP_USER"
echo "$FTP_USER:$FTP_PASS" | chpasswd

mkdir -p /var/www/html
#chown le repertoire ?

mkdir -p /var/run/vsftpd/empty


exec vsftpd /etc/vsftpd.conf
