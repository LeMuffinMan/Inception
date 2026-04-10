#!/bin/bash

source "$(dirname "$0")/lib/config.sh"
source "$(dirname "$0")/lib/format.sh"

if [[ $EUID -eq 0 ]]; then
    log_error "Run as a regular user with sudo privileges, not as root"
    log_info  "sudo is needed for: folder creation, permissions, /etc/hosts editing"
    exit 1
fi

write_secret() {
    local file="${SECRETS_DIR}/$1"
    local content="$2"
    printf '%s\n' "$content" > "$file"
    if [ -s "$file" ]; then
        check "$1" "ok"
    else
        check "$1" "ko" "file is empty after write"
    fi
}

generate_secret() {
    local len="${1:-$SECRET_LENGTH}"
    if command -v openssl > /dev/null 2>&1; then
        openssl rand -base64 "$len" | tr -d '=\n'
    elif [ -r /dev/urandom ]; then
        head -c "$len" /dev/urandom | base64 | tr -d '=\n'
    else
        echo "Error: no random source available" >&2
        return 1
    fi
}

# --- Force flag ---------------------------------------------------------------
header "Secret Generator" "login: ${LOGIN}"

# This flag will overwrite all crendentials and secrets
if [ "$1" = "-f" ]; then
    if [ -d "$SECRETS_DIR" ]; then
        log_warn "secrets/ already exists. Override? [y/n] "
        read -r res
        case "$res" in
            [yY])
                rm -rf "$SECRETS_DIR"
                log_info "secrets/ removed"
                ;;
            *)
                log_info "Canceled."
                exit 0
                ;;
        esac
    fi
fi

mkdir -p "$SECRETS_DIR"
if [ ! -d "$SECRETS_DIR" ]; then
    check "secrets/ directory" "ko" "could not create $SECRETS_DIR"
    exit 1
fi

section "Generating Secrets"

for FILE in "${CREDENTIALS_FILES[@]}"; do
    if [ ! -s "${SECRETS_DIR}/${FILE}" ]; then
        write_secret "$FILE" "$(generate_secret $SECRET_LENGTH)"
    else
        skip "$FILE"
    fi
    if ! chmod 600 "${SECRETS_DIR}/${FILE}"; then
        log_error "Failed to chmod 600 ${FILE}"
    fi
done

echo
TOTAL=$(ls "$SECRETS_DIR" | wc -l)
log_debug "${TOTAL} file(s) in ${SECRETS_DIR}"
log_info  "Use -f flag to force regeneration of all secrets"
echo

chmod 600 srcs/.env

echo
