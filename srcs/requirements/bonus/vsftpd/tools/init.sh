#!/bin/bash

export FTP_USER=$(cat /run/secrets/ftp_user)
export FTP_PASS=$(cat /run/secrets/ftp_pass)

if ! id $FTP_USER  > /dev/null 2>&1; then
    echo "Setting FTP_USER ..."
    # adduser -D -h "/home/$FTP_USER" -s /bin/sh "$FTP_USER"
    adduser -D -h /home/$FTP_USER -s /bin/false $FTP_USER
    echo "$FTP_USER:$FTP_PASS" | chpasswd
    chown -R $FTP_USER:$FTP_USER /home/$FTP_USER/ftp/

    cat > /etc/vsftpd/vsftpd.conf << EOF
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
chroot_local_user=YES
allow_writeable_chroot=YES
secure_chroot_dir=/var/empty
pam_service_name=vsftpd
pasv_enable=YES
pasv_min_port=21100
pasv_max_port=21110
seccomp_sandbox=NO
local_root=/home/$FTP_USER/ftp/
listen=YES
EOF
else
    echo "vsftpd is already configured"
fi

exec vsftpd /etc/vsftpd/vsftpd.conf
