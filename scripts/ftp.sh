#!/bin/bash

set -e

PASSWD=$(cat secrets/ftp_pass.txt)
set -a
source srcs/.env
set +a

if [ -z "$FTP_USER" ]; then
    echo "env var FTP_USER not found"
    exit 1
fi
if [ -z "$PASSWD" ]; then
    echo "secret FTP_USER not found"
    exit 1
fi

if [ -z "$1" ] || { [ -z "$2" ] && [ "$1" != "-l" ]; }; then
    echo "Usage: make ftp MODE=<d/u/l> FILE=<file-to-up/download>"
    echo "MODE=d: download <file> from ftp server"
    echo "MODE=u: upload <file> to ftp server"
    echo "MODE=l: list content of folder <FILE> on ftp server"
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
    echo "Usage: make ftp-<d/u>-<file>"
    exit 1
fi

exit 0
