#!/bin/bash

export FTP_USER=$(cat /run/secrets/ftp_user)
export FTP_PASS=$(cat /run/secrets/ftp_pass)

if ! id $FTP_USER  > /dev/null 2>&1; then
    echo "Setting FTP_USER ..."
    # adduser -D -h "/home/$FTP_USER" -s /bin/sh "$FTP_USER"
    adduser -D -h /home/$FTP_USER -s /bin/false $FTP_USER
    echo "$FTP_USER:$FTP_PASS" | chpasswd
    chown -R $FTP_USER:$FTP_USER /home/$FTP_USER/ftp/

    mkdir -p /var/log/vsftpd/
    chown -R $FTP_USER:$FTP_USER /var/log/vsftpd/
    mkdir -p /var/empty
    chown -R $FTP_USER:$FTP_USER /var/empty

    cat > /etc/vsftpd/vsftpd.conf << EOF
# write permissions
anonymous_enable=NO
local_enable=YES
write_enable=YES
chroot_local_user=YES
secure_chroot_dir=/var/empty
allow_writeable_chroot=YES
local_root=/home/$FTP_USER/ftp/

# network
listen=YES
listen_ipv6=NO
local_umask=022
connect_from_port_20=YES
dirmessage_enable=YES
pam_service_name=vsftpd
pasv_enable=YES
pasv_min_port=21100
pasv_max_port=21110
seccomp_sandbox=NO

#logs
log_ftp_protocol=YES
xferlog_enable=YES
xferlog_std_format=NO
dual_log_enable=YES
xferlog_file=/var/log/vsftpd/xferlog.log
vsftpd_log_file=/var/log/vsftpd/vsftpd.log

# one_process_model=YES
background=NO
EOF
else
    echo "vsftpd is already configured"
fi

# this line solve the 139 exit code
# exec strace -f vsftpd /etc/vsftpd/vsftpd.conf

# echo "EXEC VSFTPD"
vsftpd /etc/vsftpd/vsftpd.conf
