#!/bin/sh

# Docker monitors PID 1 : we don't want nginx to run as daemon (fork and exit)
# thus, Docker sees nginx as PID 1 running in the container, it can forward signals and monitor it
exec nginx -g "daemon off;"
