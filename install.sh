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

# Append a guarded source line to an rc file (once)
add_source_line() {
    local rc="$1"
    if ! grep -qF "$TARGET" "$rc" 2>/dev/null; then
        printf '\n# custom-daliases (adir)\n[[ -f "%s" ]] && source "%s"\n' "$TARGET" "$TARGET" >> "$rc"
        echo "Added source line to $rc"
    fi
}

# Bash: /etc/profile.d is only read by login shells, but most terminal tabs start
# interactive non-login shells, so source it from ~/.bashrc as well.
add_source_line "$HOME/.bashrc"

# zsh reads neither /etc/profile.d nor ~/.bashrc. Only touch zsh config if the user actually uses zsh.
if [[ -f "$HOME/.zshrc" || "${SHELL:-}" == */zsh ]]; then
    add_source_line "$HOME/.zshrc"
fi

echo "Done. Open a new terminal, or run: source \"$TARGET\""
