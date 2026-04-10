#!/bin/bash

# =============================================================================
# lib/format.sh — Shared formatting library for Inception check scripts
# Source this file at the top of each script:
#   source "$(dirname "$0")/lib/format.sh"
# =============================================================================

source "$(dirname "$0")/lib/config.sh"

# --- Colors -------------------------------------------------------------------

BOLD='\033[1m'
DIM='\033[2m'
GRAY='\033[0;90m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

PASS="${GREEN}${BOLD}✔ OK${NC}"
FAIL="${RED}${BOLD}✘ KO${NC}"

# Width reserved for check labels (increase if labels are longer)
LABEL_WIDTH=50

# --- Log levels ---------------------------------------------------------------
# INFO  (cyan)    : normal operational messages
# DEBUG (gray)    : verbose detail — shown only when VERBOSE=1
# WARN  (yellow)  : unexpected but non-fatal
# ERROR (red)     : critical failure, written to stderr

log_info()  { printf "${CYAN}[INFO]${NC}  %s\n" "$*"; }
log_debug() { [ "${VERBOSE:-0}" = "1" ] && printf "${GRAY}[DEBUG]${NC} %s\n" "$*" || true; }
log_warn()  { printf "${YELLOW}${BOLD}[WARN]${NC}  %s\n" "$*" >&2; }
log_error() { printf "${RED}${BOLD}[ERROR]${NC} %s\n" "$*" >&2; }

# --- UI components ------------------------------------------------------------

section() {
    echo
    echo -e "${CYAN}${BOLD}┌─────────────────────────────────────────┐${NC}"
    printf "${CYAN}${BOLD}│  %-41s│${NC}\n" "$1"
    echo -e "${CYAN}${BOLD}└─────────────────────────────────────────┘${NC}"
}

header() {
    local title="$1"
    local subtitle="$2"
    echo
    echo -e "${CYAN}${BOLD}  Inception — ${title}${NC}  ${GRAY}${subtitle}${NC}"
}

# display ok or ko and details if provided
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

# display a "skipped" line (item already exists, no action taken)
skip() {
    local label="$1"
    local pad=$(( LABEL_WIDTH - ${#label} ))
    [ $pad -lt 1 ] && pad=1
    local spaces
    spaces=$(printf '%*s' "$pad" '')
    printf "  ${WHITE}%s${NC}%s ${GRAY}⊘ skipped (already exists)${NC}\n" "$label" "$spaces"
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

# Waiting for each argument execution to returns 0
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

# --- Wait for all containers to be up and healthy -------------------------
wait_for_containers() {
    local timeout=${WAIT_TIMEOUT:-30}
    local elapsed=0
    local containers=("${CONTAINERS_TO_TEST[@]}")

    echo
    printf "  ${CYAN}${BOLD}Waiting all containers to be started and healthy${NC}\n"
    echo

    while [ $elapsed -lt $timeout ]; do
        CONTAINERS=$($COMPOSE ps 2>/dev/null)

        local all_ready=true
        local output=""

        for container in "${containers[@]}"; do
            local line
            line=$(echo "$CONTAINERS" | grep "$container")

            local status icon
            if ! echo "$line" | grep -q "Up"; then
                status="${RED}starting${NC}"; icon="${YELLOW}◌${NC}"; all_ready=false
            elif echo "$line" | grep -q "Restarting"; then
                status="${RED}restarting${NC}"; icon="${RED}✗${NC}"; all_ready=false
            elif echo "$line" | grep -q "unhealthy"; then
                status="${RED}unhealthy${NC}"; icon="${RED}✗${NC}"; all_ready=false
            elif echo "$line" | grep -q "health: starting"; then
                status="${YELLOW}health check...${NC}"; icon="${YELLOW}◌${NC}"; all_ready=false
            else
                status="${GREEN}ready${NC}"; icon="${GREEN}✓${NC}"
            fi

            output+="  ${icon}  ${WHITE}${container}${NC}  →  ${status}\033[K\n"
        done

        printf "%b" "$output"

        $all_ready && {
            echo
            printf "  ${GREEN}All containers ready${NC}  ${DIM}(${elapsed}s)${NC}\n"
            return 0
        }

        sleep 1
        ((elapsed++))

        printf "\033[${#containers[@]}A" 2>/dev/null
    done

    echo
    printf "  ${RED}${BOLD}Timeout: containers not ready after ${timeout}s${NC}\n"
    return 1
}
