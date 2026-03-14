#!/bin/bash
# =============================================================================
# lib/format.sh — Shared formatting library for Inception check scripts
# Source this file at the top of each script:
#   source "$(dirname "$0")/lib/format.sh"
# =============================================================================

# --- Colors -------------------------------------------------------------------

BOLD='\033[1m'
GRAY='\033[0;90m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

PASS="${GREEN}${BOLD}✔ OK${NC}"
FAIL="${RED}${BOLD}✘ KO${NC}"

# Width reserved for check labels (increase if labels are longer)
LABEL_WIDTH=50

section() {
    echo
    echo -e "${CYAN}${BOLD}┌─────────────────────────────────────────┐${NC}"
    printf "${CYAN}${BOLD}│  %-41s│${NC}\n" "$1"
    echo -e "${CYAN}${BOLD}└─────────────────────────────────────────┘${NC}"
}

check() {
    local label="$1"
    local status="$2"
    local detail="$3"

    local pad=$(( LABEL_WIDTH - ${#label} ))
    [ $pad -lt 1 ] && pad=1
    local spaces
    spaces=$(printf '%*s' "$pad" '')

    if [ "$status" = "ok" ]; then
        printf "  ${WHITE}%s${NC}%s ${PASS}" "$label" "$spaces"
    else
        printf "  ${WHITE}%s${NC}%s ${FAIL}" "$label" "$spaces"
    fi

    [ -n "$detail" ] && echo -e "  ${GRAY}→ ${detail}${NC}" || echo
}

pending() {
    local label="$1"
    local msg="$2"

    local pad=$(( LABEL_WIDTH - ${#label} ))
    [ $pad -lt 1 ] && pad=1
    local spaces
    spaces=$(printf '%*s' "$pad" '')

    printf "  ${WHITE}%s${NC}%s ${YELLOW}⧖ %s${NC}\n" "$label" "$spaces" "$msg"
}

header() {
    local title="$1"
    local subtitle="$2"
    echo
    echo -e "${CYAN}${BOLD}  Inception — ${title}${NC}  ${GRAY}${subtitle}${NC}"
    echo -e "${GRAY}  $(date)${NC}"
}

wait_for() {
    local timeout="$1"; shift
    local elapsed=0
    while [ $elapsed -lt $timeout ]; do
        eval "$@" && return 0
        sleep 1
        (( elapsed++ ))
    done
    return 1
}
