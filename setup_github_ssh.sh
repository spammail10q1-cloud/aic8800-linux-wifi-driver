#!/usr/bin/env bash
# setup_github_ssh.sh — Generate an SSH key and connect this repo to GitHub over SSH.
#
# Usage:
#   GITHUB_TOKEN=ghp_xxx ./setup_github_ssh.sh --user YOUR_GITHUB_USER --repo YOUR_REPO
#   ./setup_github_ssh.sh --token ghp_xxx --user YOUR_GITHUB_USER --repo YOUR_REPO
set -euo pipefail

KEY_NAME="id_ed25519_github"
KEY_PATH="$HOME/.ssh/$KEY_NAME"
SSH_CONFIG="$HOME/.ssh/config"
TOKEN="${GITHUB_TOKEN:-}"
USER_NAME=""
REPO_NAME=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --token) TOKEN="$2"; shift 2;;
        --user) USER_NAME="$2"; shift 2;;
        --repo) REPO_NAME="$2"; shift 2;;
        *) echo "Unknown arg: $1"; exit 1;;
    esac
done

if [[ -z "$USER_NAME" ]]; then
    read -rp "GitHub username: " USER_NAME
fi
if [[ -z "$REPO_NAME" ]]; then
    REPO_NAME="$(basename "$(pwd)")"
fi

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Generate key if missing
if [[ ! -f "$KEY_PATH" ]]; then
    echo "==> Generating new SSH key: $KEY_PATH"
    ssh-keygen -t ed25519 -C "$USER_NAME@github" -f "$KEY_PATH" -N ""
else
    echo "==> Reusing existing key: $KEY_PATH"
fi

# Ensure GitHub host key is known
mkdir -p "$HOME/.ssh"
touch "$HOME/.ssh/known_hosts"
if ! grep -q "github.com" "$HOME/.ssh/known_hosts"; then
    ssh-keyscan -H github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null || true
fi

# Configure SSH
touch "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"
if ! grep -q "Host github.com" "$SSH_CONFIG"; then
    cat >> "$SSH_CONFIG" <<EOF

Host github.com
    HostName github.com
    User git
    IdentityFile $KEY_PATH
    IdentitiesOnly yes
    AddKeysToAgent yes
EOF
fi

# Start agent and add key
eval "$(ssh-agent -s)" >/dev/null
ssh-add "$KEY_PATH" 2>/dev/null || true

# Upload public key to GitHub if token given
if [[ -n "$TOKEN" ]]; then
    echo "==> Uploading SSH public key to GitHub..."
    TITLE="wifi-driver-$(hostname)-$(date +%s)"
    PUBKEY="$(cat "$KEY_PATH.pub")"
    HTTP_CODE=$(curl -s -o /tmp/opencode/gh_key_resp.txt -w "%{http_code}" \
        -X POST \
        -H "Authorization: Bearer $TOKEN" \
        -H "Accept: application/vnd.github+json" \
        https://api.github.com/user/keys \
        -d "{\"title\":\"$TITLE\",\"key\":\"$PUBKEY\"}")
    if [[ "$HTTP_CODE" == "201" ]]; then
        echo "    Key uploaded successfully."
    elif [[ "$HTTP_CODE" == "422" ]]; then
        echo "    Key already exists on GitHub (OK)."
    else
        echo "    Upload failed (HTTP $HTTP_CODE):"
        cat /tmp/opencode/gh_key_resp.txt
        echo
    fi
else
    echo "==> No token provided; skipping upload."
    echo "    Add this public key manually to GitHub -> Settings -> SSH keys:"
    cat "$KEY_PATH.pub"
fi

# Switch remote to SSH if origin exists
if git remote get-url origin >/dev/null 2>&1; then
    git remote set-url origin "git@github.com:$USER_NAME/$REPO_NAME.git"
    echo "==> origin -> git@github.com:$USER_NAME/$REPO_NAME.git"
else
    git remote add origin "git@github.com:$USER_NAME/$REPO_NAME.git"
    echo "==> origin added -> git@github.com:$USER_NAME/$REPO_NAME.git"
fi

echo
echo "==> Testing SSH connection to GitHub..."
ssh -T git@github.com 2>&1 || true
echo
echo "Done. You can now: git push -u origin main"