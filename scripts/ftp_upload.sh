#!/bin/bash

if [ -z $1 ]; then
    echo "Usage: make ftp-upload <file-to-upload>"
    exit 1
fi

USER=$(cat secrets/ftp_user.txt)
PASSWD=$(cat secrets/ftp_pass.txt)

#recuperer la var depuis env
ftp -n oelleaum.42.fr <<END_SCRIPT
quote USER $USER
quote PASS $PASSWD
put ${1}
quit
END_SCRIPT
exit 0
