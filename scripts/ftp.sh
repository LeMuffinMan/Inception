#!/bin/bash

if [ -z "$1" ] || { [ -z "$2" ] && [ "$1" != "-l" ]; }; then
    echo "Usage: make ftp MODE=<d/u/l> FILE=<file-to-up/download>"
    echo "MODE=d: download <file> from ftp server"
    echo "MODE=u: upload <file> to ftp server"
    echo "MODE=l: list content of folder <FILE> on ftp server"
    exit 1
fi

USER=$(cat secrets/ftp_user.txt)
PASSWD=$(cat secrets/ftp_pass.txt)

if [ $1 == "-d" ]; then
    ftp -n localhost <<EOF
quote USER $USER
quote PASS $PASSWD
get ${2}
quit
EOF
elif [ $1 == "-u" ]; then
    ftp -n localhost <<EOF
quote USER $USER
quote PASS $PASSWD
put ${2}
quit
EOF
elif [ $1 == "-l" ]; then
    ftp -n localhost <<EOF
quote USER $USER
quote PASS $PASSWD
ls ${2}
quit
EOF
else
    echo "Usage: make ftp MODE=<d/u> FILE=<file-to-up/download>"
    exit 1
fi

exit 0
