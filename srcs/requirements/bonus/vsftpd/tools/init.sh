#!/bin/bash

set -e

# --- Colors & log functions ---------------------------------------------------
NC='\033[0m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; GREEN='\033[0;32m'
log_info()  { printf "${CYAN}[INFO]${NC}  %s\n" "$*"; }
log_warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$*" >&2; }
log_error() { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; }
# ------------------------------------------------------------------------------

FTP_PASS=$(cat /run/secrets/ftp_pass)

if ! id $FTP_USER  > /dev/null 2>&1; then
    log_info "Setting up FTP_USER: $FTP_USER ..."
    useradd -m -d /var/log/vsftpd $FTP_USER
    echo "$FTP_USER:$FTP_PASS" | chpasswd
    chown -R $FTP_USER:$FTP_USER /var/www/html

    mkdir -p /var/log/vsftpd/
    chown -R $FTP_USER:$FTP_USER /var/log/vsftpd/
    mkdir -p /var/empty
    chown -R $FTP_USER:$FTP_USER /var/empty
else
    log_info "vsftpd already configured"
fi

log_info "Starting vsftpd ..."
exec /usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf
