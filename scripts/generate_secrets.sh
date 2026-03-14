#!/bin/bash

source "$(dirname "$0")/lib/config.sh"
source "$(dirname "$0")/lib/format.sh"

# --- Helpers ------------------------------------------------------------------

# write_secret <filename> <content>
#   Writes content to secrets/<filename>, avoids subshell exposure
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

# generate_secret [length]
#   Outputs a random base64 string of given byte length
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

# skip <filename>
#   Prints a 'skipped' line for already-existing secrets
skip() {
    local pad=$(( LABEL_WIDTH - ${#1} ))
    [ $pad -lt 1 ] && pad=1
    local spaces
    spaces=$(printf '%*s' "$pad" '')
    printf "  ${WHITE}%s${NC}%s ${GRAY}⊘ skipped (already exists)${NC}\n" "$1" "$spaces"
}

# --- Force flag ---------------------------------------------------------------

header "Secret Generator" "login: ${LOGIN}"

if [ "$1" = "-f" ]; then
    if [ -d "$SECRETS_DIR" ]; then
        printf "\n  ${YELLOW}${BOLD}secrets/ already exists. Override? [y/n]${NC} "
        read -r res
        case "$res" in
            [yY])
                rm -rf "$SECRETS_DIR"
                echo -e "  ${GRAY}→ secrets/ removed${NC}"
                ;;
            *)
                echo -e "\n  ${GRAY}Canceled.${NC}\n"
                exit 0
                ;;
        esac
    fi
fi

# --- Create directory ---------------------------------------------------------

mkdir -p "$SECRETS_DIR"
if [ ! -d "$SECRETS_DIR" ]; then
    check "secrets/ directory" "ko" "could not create $SECRETS_DIR"
    exit 1
fi

section "Generating Secrets"

# --- Random secrets -----------------------------------------------------------

for FILE in db_password.txt db_root_password.txt wp_admin_password.txt wp_user_password.txt; do
    if [ ! -s "${SECRETS_DIR}/${FILE}" ]; then
        write_secret "$FILE" "$(generate_secret $SECRET_LENGTH)"
    else
        skip "$FILE"
    fi
done

# --- Static credentials -------------------------------------------------------

section "Writing Credentials"

declare -A STATIC_SECRETS=(
    ["mysql_user.txt"]="$DEFAULT_MYSQL_USER"
    ["wp_admin_user.txt"]="$DEFAULT_WP_ADMIN_USER"
    ["wp_user.txt"]="$DEFAULT_WP_USER"
    ["mysql_admin_email.txt"]="$DEFAULT_ADMIN_EMAIL"
    ["mysql_user_email.txt"]="$DEFAULT_USER_EMAIL"
)

for FILE in "${!STATIC_SECRETS[@]}"; do
    if [ ! -s "${SECRETS_DIR}/${FILE}" ]; then
        write_secret "$FILE" "${STATIC_SECRETS[$FILE]}"
    else
        skip "$FILE"
    fi
done

# --- Summary ------------------------------------------------------------------

echo
TOTAL=$(ls "$SECRETS_DIR" | wc -l)
echo -e "  ${GRAY}→ ${TOTAL} file(s) in ${SECRETS_DIR}${NC}"
echo -e "  ${GRAY}→ Use ${WHITE}-f${GRAY} flag to force regeneration of all secrets${NC}"
echo
