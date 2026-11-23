#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_FILE="$REPO_DIR/src/custom-daliases.sh"

if [[ ! -f "$SRC_FILE" ]]; then
    echo "Error: Could not find $SRC_FILE" >&2
    exit 1
fi

if [[ -w /etc/profile.d ]] || command -v sudo >/dev/null 2>&1; then
    TARGET="/etc/profile.d/custom-daliases.sh"
    if [[ -w /etc/profile.d ]]; then
        cp "$SRC_FILE" "$TARGET"
        chmod 644 "$TARGET"
    else
        sudo cp "$SRC_FILE" "$TARGET"
        sudo chmod 644 "$TARGET"
    fi
    echo "Installed system-wide to $TARGET"
else
    TARGET="$HOME/.custom-daliases.sh"
    cp "$SRC_FILE" "$TARGET"
    chmod 644 "$TARGET"
    for rc in "$HOME/.bashrc" "$HOME/.bash_profile"; do
        if [[ -f "$rc" ]] && ! grep -qF "$TARGET" "$rc"; then
            printf '\n# Custom *dir directory aliases\n[[ -f "%s" ]] && source "%s"\n' "$TARGET" "$TARGET" >> "$rc"
        fi
    done
    echo "Installed to $TARGET"
fi

# zsh does not read /etc/profile.d or ~/.bashrc, so source the script from ~/.zshrc
if command -v zsh >/dev/null 2>&1 || [[ -f "$HOME/.zshrc" ]]; then
    if ! grep -qF "$TARGET" "$HOME/.zshrc" 2>/dev/null; then
        printf '\n# custom-daliases (adir)\n[[ -f "%s" ]] && source "%s"\n' "$TARGET" "$TARGET" >> "$HOME/.zshrc"
        echo "Added source line to $HOME/.zshrc (zsh)"
    fi
fi
