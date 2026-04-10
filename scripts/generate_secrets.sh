#!/bin/bash

# A reclean avec la modif du config.sh

if [[ $EUID -eq 0 ]]; then
    echo "You must have sudo privilege to setup this project, to perform following operations:
        - Create folders, attribute it to other users, their deletion (make fclean) require sudo
        - Edit /etc/hosts to redirect 127.0.0.1 to your domain name instead of localhost"
    exit 1
fi

# ici verifier la presence du .env et des variables minimales a avoir

# Si pas de .env / pas de secrets, afficher une liste des fichiers qui seront generes et demander confirmation

source "$(dirname "$0")/lib/config.sh"
source "$(dirname "$0")/lib/format.sh"

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

skip() {
    local pad=$(( LABEL_WIDTH - ${#1} ))
    [ $pad -lt 1 ] && pad=1
    local spaces
    spaces=$(printf '%*s' "$pad" '')
    printf "  ${WHITE}%s${NC}%s ${GRAY}⊘ skipped (already exists)${NC}\n" "$1" "$spaces"
}

# creates .env file in srcs/
# generates all variables and fill them with default value
generate_env() {
    mkdir -p "$(dirname "$ENV_FILE")"
    for VAR in "${ORDERED_VARS[@]}"; do
        printf '%s=%s\n' "$VAR" "${EXPECTED_VALUES[$VAR]}"
    done > "$ENV_FILE"

    if [ -s "$ENV_FILE" ]; then
        check "$ENV_FILE" "ok" "generated"
    else
        check "$ENV_FILE" "ko" "could not write $ENV_FILE"
    fi
}
# --- Force flag ---------------------------------------------------------------
header "Secret Generator" "login: ${LOGIN}"

# This flag will overwrite all crendentials and secrets
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
        echo "Failed to chmod 600 ${FILE}"
    fi
done

echo
TOTAL=$(ls "$SECRETS_DIR" | wc -l)
echo -e "  ${GRAY}→ ${TOTAL} file(s) in ${SECRETS_DIR}${NC}"
echo -e "  ${GRAY}→ Use ${WHITE}-f${GRAY} flag to force regeneration of all secrets${NC}"
echo

chmod 600 srcs/.env

echo
