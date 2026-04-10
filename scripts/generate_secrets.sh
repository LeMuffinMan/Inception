#!/bin/bash

source "$(dirname "$0")/lib/config.sh"
source "$(dirname "$0")/lib/format.sh"

if [[ $EUID -eq 0 ]]; then
    log_error "Run as a regular user with sudo privileges, not as root"
    log_info  "sudo is needed for: folder creation, permissions, /etc/hosts editing"
    exit 1
fi

get_var() {
    local var_name="$1"
    local var_value=""
    while [ -z "$var_value" ]; do
        read -p "  $var_name= " var_value
    done
    echo "$var_value"
}

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
        log_error "no random source available"
        return 1
    fi
}

header "Setup" "login: ${LOGIN}"

FORCE_SECRETS=0
[ "$1" = "-f" ] && FORCE_SECRETS=1

# =============================================================================
# .env
# =============================================================================

section "Environment (.env)"

AUTO_GEN="$(dirname "$0")/auto_generate_env.sh"

if [ ! -s "$ENV_FILE" ]; then
    read -p "  No .env found — generate with defaults? [y/n] " res
    if [ "$res" = "y" ] && [ -f "$AUTO_GEN" ]; then
        "$AUTO_GEN"
        log_info ".env generated with defaults"
    else
        touch "$ENV_FILE"
    fi
fi

set -a
if ! source "$ENV_FILE" 2>/dev/null; then
    log_error "Failed to source $ENV_FILE"
    exit 1
fi
set +a

missing=0
for var in "${REQUIRED_ENV_VARS[@]}"; do
    [ -z "${!var}" ] && missing=1 && break
done

if [ "$missing" = "1" ]; then
    log_info "Fill in the missing variables:"
    echo
    for var in "${REQUIRED_ENV_VARS[@]}"; do
        if [ -z "${!var}" ]; then
            if [ "$var" = "MYSQL_ADMIN_EMAIL" ]; then
                while true; do
                    val=$(get_var "$var")
                    if [ "$val" = "$MYSQL_USER_EMAIL" ]; then
                        log_warn "That email is already used — WordPress requires 2 different email addresses"
                    else
                        MYSQL_ADMIN_EMAIL="$val"
                        printf '%s=%s\n' "$var" "$val" >> "$ENV_FILE"
                        break
                    fi
                done
            else
                val=$(get_var "$var")
                printf '%s=%s\n' "$var" "$val" >> "$ENV_FILE"
                export "$var"="$val"
            fi
        fi
    done
    echo
fi

for var in "${REQUIRED_ENV_VARS[@]}"; do
    if [ -n "${!var}" ]; then
        check "$var" "ok"
    else
        check "$var" "ko" "still missing"
    fi
done

chmod 600 "$ENV_FILE"

# =============================================================================
# Secrets
# =============================================================================

section "Generating Secrets"

if [ "$FORCE_SECRETS" = "1" ] && [ -d "$SECRETS_DIR" ]; then
    log_warn "secrets/ already exists. Override? [y/n] "
    read -r res
    case "$res" in
        [yY])
            rm -rf "$SECRETS_DIR"
            log_info "secrets/ removed"
            ;;
        *)
            log_info "Canceled — keeping existing secrets."
            FORCE_SECRETS=0
            ;;
    esac
fi

mkdir -p "$SECRETS_DIR"
if [ ! -d "$SECRETS_DIR" ]; then
    check "secrets/ directory" "ko" "could not create $SECRETS_DIR"
    exit 1
fi

echo
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
log_debug "$(ls "$SECRETS_DIR" | wc -l) file(s) in ${SECRETS_DIR}"
log_info  "Use -f flag to force regeneration of all secrets"
echo
