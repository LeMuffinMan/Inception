#!/bin/bash

FTP_USER=$(cat /run/secrets/ftp_user)
FTP_PASS=$(cat /run/secrets/ftp_pass)

if ! id $FTP_USER  > /dev/null 2>&1; then
    echo "Setting FTP_USER ..."
    adduser -D -h "/home/$FTP_USER" "$FTP_USER"
    echo "$FTP_USER:$FTP_PASS" | chpasswd
else
    echo "vsftpd is already configured"
fi

# mkdir -p /var/run/vsftpd/empty

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/vsftpd/vsftpd.pem \
    -out /etc/vsftpd/vsftpd.pem \
    -subj "/C=CO/ST=REG/L=City/O=42/CN=Common_Name"

chmod 600 /etc/vsftpd/vsftpd.pem

cat > /etc/vsftpd/vsftpd.conf << 'EOF'
listen=YES
listen_ipv6=NO
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
chroot_local_user=YES
allow_writeable_chroot=YES
secure_chroot_dir=/var/run/vsftpd/empty
pasv_enable=YES
pasv_min_port=21100
pasv_max_port=21110
ssl_enable=YES
force_local_data_ssl=YES
force_local_logins_ssl=YES
rsa_cert_file=/etc/vsftpd/vsftpd.pem
EOF

echo "Starting vsftpd ..."
exec vsftpd /etc/vsftpd/vsftpd.conf || echo "Failed to start vsftpd"
