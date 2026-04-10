#!/bin/bash

if [ "$EUID" -eq 0 ]; then
    echo "You are running this script/command as root, only being sudoer is required"
fi

if ! sudo -n true > 2>/dev/null; then
    echo "You must be in sudoers group to run this script/command"
    exit 1
fi
