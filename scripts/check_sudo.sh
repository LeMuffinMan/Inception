#!/bin/bash

RED='\033[0;31m'
RESET='\033[0m'

if ! sudo true 2>/dev/null; then
    printf "${RED}Sudo privileges are required for system tasks (volume management and host configuration${RESET}\n"
    printf "Ensure your user is in the sudoers group\n"
    exit 1
fi

exit 0
