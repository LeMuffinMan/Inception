#!/bin/bash

FTP_USER=$(cat /run/secrets/ftp_user)
FTP_PASS=$(cat /run/secrets/ftp_pass)

# on peut peut etre override le suer ?
if ! id $FTP_USER  > /dev/null 2>&1; then
    echo "Setting FTP_USER ..."
    adduser -D -h "/home/$FTP_USER" "$FTP_USER"
    echo "$FTP_USER:$FTP_PASS" | chpasswd
else
    echo "vsftpd is already configured"
fi

mkdir -p /var/run/vsftpd/empty

FORM="/C=CO/ST=REG/L=City/O=42/CN=oelleaum.42.fr"
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -out /etc/ssl/private/vsftpd.cert.pem \
    -keyout /etc/ssl/private/vsftpd.key.pem \
    -subj "/C=CO/ST=REG/L=City/O=42/CN=oelleaum.42.fr"

# Vsftp s'exécute avec les droits de l'utilisateur nobody mais il se lance en tant que root et donc lit le certificat en tant que root.
sudo chown root:root /etc/ssl/private/vsftpd.cert.pem /etc/ssl/private/vsftpd.key.pem
sudo chmod 600 /etc/ssl/private/vsftpd.cert.pem /etc/ssl/private/vsftpd.key.pem

# Ensure directory and permissions for the FTP user
mkdir -p /home/$FTP_USER
chown -R $FTP_USER:$FTP_USER /home/$FTP_USER
chmod 700 /home/$FTP_USER

echo "$FTP_USER" > /etc/vsftpd/chroot_list

cat > /etc/vsftpd/vsftpd.conf << EOF
listen=YES
listen_ipv6=NO
background=NO
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
chroot_list_enable=YES
chroot_list_file=/etc/vsftpd/chroot_list
secure_chroot_dir=/var/run/vsftpd/empty
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=40100
pasv_addr_resolve=YES
pasv_address=oelleaum.42.fr
ssl_enable=YES
allow_anon_ssl=NO
force_local_data_ssl=NO
force_local_logins_ssl=YES
ssl_tlsv1_2=YES
ssl_sslv2=NO
ssl_sslv3=NO
rsa_cert_file=/etc/ssl/private/vsftpd.cert.pem
rsa_private_key_file=/etc/ssl/private/vsftpd.key.pem
log_ftp_protocol=YES
EOF

echo "Starting vsftpd ..."
exec vsftpd /etc/vsftpd/vsftpd.conf
