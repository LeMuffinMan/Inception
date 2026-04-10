#!/bin/bash

source "$(dirname "$0")/lib/format.sh"

if ! sudo true 2>/dev/null; then
    log_error "Sudo privileges are required for system tasks (volume management and host configuration)"
    log_warn  "Ensure your user is in the sudoers group"
    exit 1
fi

exit 0
