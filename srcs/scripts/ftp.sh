#!/bin/bash

set -e

PASSWD=$(cat secrets/ftp_pass.txt)
set -a
source srcs/.env
set +a

source "$(dirname "$0")/lib/format.sh"

if [ -z "$FTP_USER" ]; then
    log_error "env var FTP_USER not found"
    exit 1
fi
if [ -z "$PASSWD" ]; then
    log_error "secret ftp_pass.txt not found or empty"
    exit 1
fi

if [ -z "$1" ] || { [ -z "$2" ] && [ "$1" != "-l" ]; }; then
    log_info "Usage: make ftp-<list|dl-FILE|up-FILE>"
    log_info "  -d <file>  download file from ftp server"
    log_info "  -u <file>  upload file to ftp server"
    log_info "  -l         list content of ftp server"
    exit 1
fi


if [ $1 == "-d" ]; then
    ftp -n 127.0.0.1 <<EOF
quote USER $FTP_USER
quote PASS $PASSWD
binary
get ${2}
quit
EOF
elif [ $1 == "-u" ]; then
    ftp -n 127.0.0.1 <<EOF
quote USER $FTP_USER
quote PASS $PASSWD
put ${2}
quit
EOF
elif [ $1 == "-l" ]; then
    ftp -n 127.0.0.1 <<EOF
quote USER $FTP_USER
quote PASS $PASSWD
ls ${2}
quit
EOF
else
    log_error "Unknown option: $1"
    log_info  "Usage: make ftp-<list|dl-FILE|up-FILE>"
    exit 1
fi

exit 0
