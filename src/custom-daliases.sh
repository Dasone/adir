#!/usr/bin/env bash
# Custom directory shortcuts & optional shell aliases (adir)
# Works in Bash and Zsh: source this file from your shell startup file.

_DALIASES_STORE_DEFAULT="${XDG_CONFIG_HOME:-$HOME/.config}/custom-daliases"
_DALIASES_DB_DEFAULT="${_DALIASES_STORE_DEFAULT}/dirs.tsv"
_DALIASES_ALIASES_FILE_DEFAULT="${_DALIASES_STORE_DEFAULT}/shell_aliases.sh"

_DALIASES_HISTORY_MAX=10
_daliases_history_file() { echo "${DALIASES_HISTORY_FILE:-$(dirname "$(_daliases_db_path)")/history}"; }

_daliases_db_path() { echo "${DALIASES_DB_FILE:-$_DALIASES_DB_DEFAULT}"; }
_daliases_aliases_file() { echo "${DALIASES_SHELL_ALIASES_FILE:-$_DALIASES_ALIASES_FILE_DEFAULT}"; }

_daliases_ensure_store() {
    local db aliases_file
    db="$(_daliases_db_path)"
    aliases_file="$(_daliases_aliases_file)"
    mkdir -p "$(dirname "$db")" "$(dirname "$aliases_file")"
    [[ -f "$db" ]] || : > "$db"
    [[ -f "$aliases_file" ]] || : > "$aliases_file"
}

# Subcommand names that cannot be used as shortcut names (so `adir <name>` is unambiguous)
_DALIASES_RESERVED_NAMES="history hist go list daliases aliasdir pick jump add adddir update updadir del deldir alias check checkdir help"

_daliases_is_reserved_name() {
    local w
    for w in $_DALIASES_RESERVED_NAMES; do
        [[ "$1" == "$w" ]] && return 0
    done
    return 1
}

_daliases_is_valid_name() {
    [[ "$1" =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]]
}

_daliases_expand_path() {
    local p="$1"
    if [[ "$p" == ~* ]]; then
        eval "printf '%s\n' \"$p\""
    else
        printf '%s\n' "$p"
    fi
}

# Prints alias|keyword|function|builtin|file for an existing command, nothing otherwise
_daliases_cmd_type() {
    if [[ -n "${ZSH_VERSION-}" ]]; then
        local t
        t="$(whence -w -- "$1" 2>/dev/null)" || return 0
        t="${t##*: }"
        case "$t" in
            none|"") ;;
            command) echo file ;;
            reserved) echo keyword ;;
            *) echo "$t" ;;
        esac
    else
        type -t "$1" 2>/dev/null || true
    fi
}

# Read one key / the rest of an escape sequence into the variable named by $1
_daliases_read_key() {
    if [[ -n "${ZSH_VERSION-}" ]]; then IFS= read -rsk1 "$1"; else IFS= read -rsn1 "$1"; fi
}
_daliases_read_seq() {
    if [[ -n "${ZSH_VERSION-}" ]]; then IFS= read -rsk2 -t 0.05 "$1"; else IFS= read -rsn2 -t 0.05 "$1"; fi
}

# Turn a relative path (".", "..", "sub/dir") into an absolute one. Absolute paths,
# ~ and $VAR paths are returned as typed. Fails if a relative path is not a directory.
_daliases_absolute_path() {
    case "$1" in
        /*|~*|\$*) printf '%s\n' "$1" ;;
        *) (CDPATH= cd -- "$1" 2>/dev/null && pwd -P) ;;
    esac
}

_daliases_check_command_conflict() {
    local name="$1"
    local existing_type
    existing_type="$(_daliases_cmd_type "$name")"
    if [[ -n "$existing_type" ]]; then
        echo "Conflict: '$name' already exists as a shell $existing_type." >&2
        return 1
    fi
    if command -v "$name" >/dev/null 2>&1; then
        echo "Conflict: '$name' resolves to '$(command -v "$name")'." >&2
        return 1
    fi
    return 0
}

_daliases_load_shell_aliases() {
    local aliases_file
    aliases_file="$(_daliases_aliases_file)"
    # shellcheck source=/dev/null
    if [[ -f "$aliases_file" ]]; then
        source "$aliases_file"
    fi
    return 0
}

_daliases_sync_shell_aliases_file() {
    _daliases_ensure_store
    local db aliases_file tmp_file name raw_path promoted expanded
    db="$(_daliases_db_path)"
    aliases_file="$(_daliases_aliases_file)"
    tmp_file="$(mktemp)"
    : > "$tmp_file"

    while IFS=$'\t' read -r name raw_path promoted; do
        [[ -z "$name" || -z "$raw_path" ]] && continue
        if [[ "$promoted" == "1" ]]; then
            expanded="$(_daliases_expand_path "$raw_path")"
            printf 'alias %s=%q\n' "$name" "cd $(printf '%q' "$expanded")" >> "$tmp_file"
        fi
    done < "$db"

    mv "$tmp_file" "$aliases_file"
    # shellcheck source=/dev/null
    source "$aliases_file"
}

_daliases_get_path() {
    awk -F'\t' -v k="$1" '$1 == k { print $2; exit }' "$(_daliases_db_path)"
}

_daliases_list_names() {
    local db
    db="$(_daliases_db_path)"
    [[ -f "$db" ]] && awk -F'\t' 'NF >= 2 && $1 != "" { print $1 }' "$db" | LC_ALL=C sort -u
}

_daliases_set_row() {
    local target_name="$1" target_path="$2" mode="$3"
    local db
    db="$(_daliases_db_path)"
    python3 - "$db" "$target_name" "$target_path" "$mode" <<'PYEOF'
import sys
from pathlib import Path

db_path = Path(sys.argv[1])
name, path, mode = sys.argv[2], sys.argv[3], sys.argv[4]
rows, found = [], False

for line in db_path.read_text(encoding="utf-8", errors="ignore").splitlines():
    if not line.strip():
        continue
    parts = line.split("\t")
    n = parts[0]
    p = parts[1] if len(parts) > 1 else ""
    promo = parts[2] if len(parts) > 2 else "0"
    if n == name:
        found = True
        if mode == "delete":
            continue
        new_p = path if path != "" else p
        new_promo = "1" if mode == "on" else ("0" if mode == "off" else promo)
        rows.append(f"{n}\t{new_p}\t{new_promo}")
    else:
        rows.append(f"{n}\t{p}\t{promo}")

if not found and mode in ("add", "on"):
    rows.append(f"{name}\t{path}\t{'1' if mode == 'on' else '0'}")

db_path.write_text("\n".join(rows) + ("\n" if rows else ""), encoding="utf-8")
PYEOF
}

_daliases_add() {
    local name="$1" raw_path="$2" make_alias=0
    shift 2 2>/dev/null || true
    [[ "${1:-}" == "--alias" ]] && make_alias=1
    if [[ -z "$name" || -z "$raw_path" ]]; then
        echo "Usage: adir add <name> <path> [--alias]" >&2; return 1
    fi
    if ! _daliases_is_valid_name "$name"; then
        echo "Invalid name '$name'." >&2; return 1
    fi
    if _daliases_is_reserved_name "$name"; then
        echo "'$name' is a reserved adir command and cannot be used as a shortcut name." >&2; return 1
    fi
    # Resolve relative paths (e.g. ".", "..", "sub/dir") to absolute ones
    local resolved
    resolved="$(_daliases_absolute_path "$raw_path")" || {
        echo "Directory does not exist: $raw_path" >&2; return 1
    }
    raw_path="$resolved"
    local expanded
    expanded="$(_daliases_expand_path "$raw_path")"
    if [[ ! -d "$expanded" ]]; then
        echo "Directory does not exist: $raw_path" >&2; return 1
    fi
    if [[ "$make_alias" -eq 1 ]] && ! _daliases_check_command_conflict "$name"; then
        return 1
    fi
    _daliases_ensure_store
    _daliases_set_row "$name" "$raw_path" "$([[ "$make_alias" -eq 1 ]] && echo on || echo add)"
    [[ "$make_alias" -eq 1 ]] && _daliases_sync_shell_aliases_file
    echo "Saved '$name' -> $raw_path"
}

_daliases_update() {
    local name="$1" raw_path="$2"
    [[ -z "$name" || -z "$raw_path" ]] && { echo "Usage: adir update <name> <path>" >&2; return 1; }
    local resolved expanded
    resolved="$(_daliases_absolute_path "$raw_path")" || {
        echo "Directory does not exist: $raw_path" >&2; return 1
    }
    raw_path="$resolved"
    expanded="$(_daliases_expand_path "$raw_path")"
    [[ -d "$expanded" ]] || { echo "Directory does not exist: $raw_path" >&2; return 1; }
    [[ -n "$(_daliases_get_path "$name")" ]] || { echo "Shortcut '$name' not found." >&2; return 1; }
    _daliases_set_row "$name" "$raw_path" "update"
    _daliases_sync_shell_aliases_file
    echo "Updated '$name' -> $raw_path"
}

_daliases_del() {
    [[ -z "$1" ]] && { echo "Usage: adir del <name>" >&2; return 1; }
    unalias "$1" 2>/dev/null || true
    _daliases_set_row "$1" "" "delete"
    _daliases_sync_shell_aliases_file
    echo "Removed '$1'"
}

_daliases_promote_alias() {
    local name="$1" mode="${2:-on}"
    [[ -z "$name" ]] && { echo "Usage: adir alias <name> [on|off]" >&2; return 1; }
    [[ -n "$(_daliases_get_path "$name")" ]] || { echo "Shortcut '$name' not found." >&2; return 1; }
    if [[ "$mode" == "off" ]]; then
        unalias "$name" 2>/dev/null || true
        _daliases_set_row "$name" "" "off"
        _daliases_sync_shell_aliases_file
        echo "Disabled shell alias for '$name'."
        return 0
    fi
    _daliases_check_command_conflict "$name" || return 1
    _daliases_set_row "$name" "" "on"
    _daliases_sync_shell_aliases_file
    echo "Enabled shell alias '$name'."
}

# Colours for list output (same palette as `adir help`); plain when piped or NO_COLOR is set
_daliases_colors() {
    if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
        C_B=$'\033[1m'; C_D=$'\033[2m'; C_C=$'\033[36m'; C_G=$'\033[32m'
        C_Y=$'\033[33m'; C_R=$'\033[31m'; C_0=$'\033[0m'
    else
        C_B=""; C_D=""; C_C=""; C_G=""; C_Y=""; C_R=""; C_0=""
    fi
}

_daliases_list() {
    _daliases_ensure_store
    local db C_B C_D C_C C_G C_Y C_R C_0
    db="$(_daliases_db_path)"
    _daliases_colors

    if [[ -n "${1:-}" ]]; then
        local want="$1" n p promo found=0 scope
        while IFS=$'\t' read -r n p promo; do
            [[ "$n" == "$want" ]] || continue
            found=1
            scope="${C_D}adir${C_0}"
            [[ "$promo" == "1" ]] && scope="${C_Y}alias${C_0}"
            printf '\n'
            printf '  %sShortcut:%s %s%s%s\n' "$C_B$C_C" "$C_0" "$C_G" "$n" "$C_0"
            printf '  %sShell:%s    %s\n' "$C_B$C_C" "$C_0" "$scope"
            printf '  %sTarget:%s   "%s"\n' "$C_B$C_C" "$C_0" "$p"
            [[ -d "$(_daliases_expand_path "$p")" ]] || printf '  %s[MISSING] directory does not exist%s\n' "$C_R" "$C_0"
            printf '\n'
        done < "$db"
        [[ "$found" -eq 1 ]] || { echo "Shortcut '$want' not found." >&2; return 1; }
        return 0
    fi

    if [[ ! -s "$db" ]]; then
        printf '\n  %sNo shortcuts defined yet.%s\n' "$C_B" "$C_0"
        printf '  Add one with %sadir add <name> <path>%s\n' "$C_G" "$C_0"
        printf '  Type %sadir help%s for more info.\n\n' "$C_G" "$C_0"
        return 0
    fi

    local rows=() name raw_path promo w=8 total=0 missing=0
    while IFS=$'\t' read -r name raw_path promo; do
        [[ -z "$name" ]] && continue
        rows+=("$name"$'\t'"$raw_path"$'\t'"$promo")
        (( ${#name} > w )) && w=${#name}
    done < <(LC_ALL=C sort -t$'\t' -k1,1 "$db")
    w=$((w + 3))

    printf '\n'
    printf '  %s%-*s %-7s %s%s\n' "$C_B$C_C" "$w" "SHORTCUT" "SCOPE" "TARGET" "$C_0"
    printf '  %s%s%s\n' "$C_D" "$(printf '%*s' $((w + 8 + 30)) '' | tr ' ' '-')" "$C_0"
    local row scope pad
    for row in "${rows[@]}"; do
        IFS=$'\t' read -r name raw_path promo <<< "$row"
        total=$((total + 1))
        pad=$(printf '%*s' $((w - ${#name})) '')
        if [[ "$promo" == "1" ]]; then scope="${C_Y}alias  ${C_0}"; else scope="${C_D}adir   ${C_0}"; fi
        if [[ -d "$(_daliases_expand_path "$raw_path")" ]]; then
            printf '  %s%s%s%s %s %s\n' "$C_G" "$name" "$C_0" "$pad" "$scope" "$raw_path"
        else
            missing=$((missing + 1))
            printf '  %s%s%s%s %s %s%s [MISSING]%s\n' "$C_G" "$name" "$C_0" "$pad" "$scope" "$C_R" "$raw_path" "$C_0"
        fi
    done
    printf '\n  %s%d shortcut(s)' "$C_D" "$total"
    (( missing > 0 )) && printf ' · %d missing' "$missing"
    printf ' · adir help for more info%s\n\n' "$C_0"
}

_daliases_go_to() {
    [[ -z "$1" ]] && { echo "Usage: adir go <name>" >&2; return 1; }
    local raw_path expanded
    raw_path="$(_daliases_get_path "$1")"
    [[ -n "$raw_path" ]] || { echo "Unknown shortcut: $1" >&2; return 1; }
    expanded="$(_daliases_expand_path "$raw_path")"
    [[ -d "$expanded" ]] || { echo "Target directory does not exist: $raw_path" >&2; return 1; }
    cd "$expanded" || return 1
    _daliases_history_add "$1"
}

# Record a visited shortcut: newest last, no duplicates, at most $_DALIASES_HISTORY_MAX entries
_daliases_history_add() {
    local hist tmp
    hist="$(_daliases_history_file)"
    mkdir -p "$(dirname "$hist")" 2>/dev/null || return 0
    tmp="$(mktemp 2>/dev/null)" || return 0
    { [[ -f "$hist" ]] && grep -vxF -- "$1" "$hist"; printf '%s\n' "$1"; } | tail -n "$_DALIASES_HISTORY_MAX" > "$tmp"
    mv "$tmp" "$hist"
    return 0
}

# adir history: arrow-key selector over recently visited shortcuts (bottom = most recent)
_daliases_history() {
    local hist name raw_path
    local names=() targets=()
    hist="$(_daliases_history_file)"
    if [[ -f "$hist" ]]; then
        while IFS= read -r name; do
            [[ -z "$name" ]] && continue
            raw_path="$(_daliases_get_path "$name")"
            [[ -n "$raw_path" ]] || continue   # shortcut was deleted since
            names+=("$name"); targets+=("$raw_path")
        done < "$hist"
    fi
    local count="${#names[@]}"
    [[ "$count" -gt 0 ]] || { echo "No history yet. Navigate with: adir go <name>"; return 0; }

    local i w=0
    for ((i = 0; i < count; i++)); do (( ${#names[i]} > w )) && w=${#names[i]}; done

    # Not a terminal: just print the list
    if [[ ! -t 0 || ! -t 1 ]]; then
        for ((i = 0; i < count; i++)); do printf '%-*s  %s\n' "$w" "${names[i]}" "${targets[i]}"; done
        return 0
    fi

    local sel=$((count - 1)) key rest first=1
    local rev=$'\033[7m' off=$'\033[0m' dim=$'\033[2m' red=$'\033[31m'

    _adir_hist_draw() {
        local j line
        if [[ "$first" -eq 0 ]]; then printf '\033[%dA' $((count + 1)); fi
        first=0
        for ((j = 0; j < count; j++)); do
            line="$(printf '%-*s  %s' "$w" "${names[j]}" "${targets[j]}")"
            [[ -d "$(_daliases_expand_path "${targets[j]}")" ]] || line="${line} [MISSING]"
            if [[ "$j" -eq "$sel" ]]; then
                printf '\r\033[K %s> %s%s\n' "$rev" "$line" "$off"
            else
                printf '\r\033[K   %s\n' "$line"
            fi
        done
        printf '\r\033[K%s  ↑/↓ move · Enter go · q/Esc cancel%s\n' "$dim" "$off"
    }

    # Remove the selector from the screen again (cursor goes back to where it started)
    _adir_hist_erase() { printf '\033[%dA\r\033[J\033[?25h' $((count + 1)); }

    printf '\033[?25l'
    _adir_hist_draw
    while true; do
        _daliases_read_key key || { printf '\033[?25h'; return 1; }
        case "$key" in
            $'\033')
                rest=""
                _daliases_read_seq rest || true
                case "$rest" in
                    '[A'|'OA') (( sel > 0 )) && sel=$((sel - 1)) ;;
                    '[B'|'OB') (( sel < count - 1 )) && sel=$((sel + 1)) ;;
                    '') _adir_hist_erase; return 0 ;;
                esac ;;
            k) (( sel > 0 )) && sel=$((sel - 1)) ;;
            j) (( sel < count - 1 )) && sel=$((sel + 1)) ;;
            q) _adir_hist_erase; return 0 ;;
            ''|$'\n'|$'\r') _adir_hist_erase; _daliases_go_to "${names[sel]}"; return $? ;;
        esac
        _adir_hist_draw
    done
}

_daliases_pick_and_cd() {
    local names=() n choice
    while IFS= read -r n; do [[ -n "$n" ]] && names+=("$n"); done < <(_daliases_list_names)
    [[ "${#names[@]}" -gt 0 ]] || { echo "No shortcuts available." >&2; return 1; }
    PS3="Select shortcut number: "
    select choice in "${names[@]}"; do
        [[ -n "$choice" ]] && { _daliases_go_to "$choice"; return $?; }
    done
}

_daliases_check() {
    _daliases_ensure_store
    local db total=0 missing=0 name raw_path promo
    db="$(_daliases_db_path)"
    echo "Store file : $db"
    while IFS=$'\t' read -r name raw_path promo; do
        [[ -z "$name" ]] && continue
        total=$((total + 1))
        [[ -d "$(_daliases_expand_path "$raw_path")" ]] || { echo "  [MISSING] $name -> $raw_path"; missing=$((missing + 1)); }
    done < "$db"
    echo "Shortcuts  : $total total, $missing missing"
}

_daliases_help() {
    local b="[1m" d="[2m" c="[36m" g="[32m" y="[33m" r="[0m"
    cat <<HELPEOF

${b}${c}====================================================================${r}
${b}${c}  ADIR — Named Directory Shortcuts & Safe Shell Aliases${r}
${b}${c}====================================================================${r}

${b}WHAT IT IS${r}
  A lightweight Bash/Zsh directory jumper that lets you save shortcuts under
  any name (no *dir suffix required) and jump straight to them with Tab
  completion or an interactive menu—without cluttering your global shell
  namespace unless you explicitly opt in.

${b}HOW IT WORKS${r}
  * ${b}Registry-first (${d}dirs.tsv${r}${b}):${r} Shortcuts are stored in your config directory
    and used inside ${g}adir go <name>${r}, ${g}adir pick${r}, and ${g}adir list${r}.
  * ${b}Opt-in shell aliases (${d}shell_aliases.sh${r}${b}):${r} Pass ${y}--alias${r} or run
    ${g}adir alias <name> on${r} to expose a shortcut as a standalone ${g}cd${r} alias
    outside ${b}adir${r}.
  * ${b}Collision protection:${r} Before creating any standalone shell alias,
    ${b}adir${r} checks builtins, keywords, functions, aliases, and ${d}PATH${r} so
    you never accidentally shadow an existing Linux command.

${b}COMMANDS${r}
  ${g}adir${r} / ${g}adir list${r}        List shortcuts, scope (${d}adir${r} vs ${y}alias${r}), and targets
  ${g}adir go <name>${r}          Jump directly to a shortcut (${b}Tab${r} completion enabled)
  ${g}adir <name>${r}             Shorthand for ${d}adir go <name>${r} (command names are reserved)
  ${g}adir pick${r} / ${g}adir jump${r}   Interactive numbered picker to select and ${d}cd${r}
  ${g}adir list <name>${r}        Show details for one shortcut
  ${g}adir history${r}            Pick from your last 10 visited shortcuts (${b}↑/↓${r} + ${b}Enter${r})
  ${g}adir add <name> <path>${r}  Save a new shortcut (${d}add --alias${r} to also make alias)
  ${g}adir update <name> <path>${r}
                            Update an existing shortcut's target directory
  ${g}adir del <name>${r}         Delete a shortcut (and remove its alias if active)
  ${g}adir alias <name> [on|off]${r}
                            Toggle standalone shell alias outside ${b}adir${r}
  ${g}adir check${r}              Verify config files and highlight missing paths
  ${g}adir help${r}               Display this reference

${b}EXAMPLES${r}
  ${d}# Add a shortcut scoped to adir (no global alias created)${r}
  adir add notes ~/documents/notes
  adir go notes

  ${d}# Save the current directory (relative paths are stored as absolute)${r}
  adir add here .

  ${d}# Add a shortcut and expose it as a direct shell command (if safe)${r}
  adir add proj ~/code/my-project --alias
  proj

  ${d}# Turn off the standalone alias while keeping the shortcut${r}
  adir alias proj off

${b}${c}--------------------------------------------------------------------${r}
${d}Config: \${DALIASES_DB_FILE:-~/.config/custom-daliases/dirs.tsv}${r}
${b}${c}====================================================================${r}

HELPEOF
}

adir() {
    # In zsh, run in ksh-compatible mode (0-based arrays, word splitting) so the Bash code works unchanged
    [[ -n "${ZSH_VERSION-}" ]] && emulate -L ksh
    local sub="${1:-list}"
    case "$sub" in
        go) _daliases_go_to "$2" ;;
        list|daliases|aliasdir) _daliases_list "$2" ;;
        pick|jump) _daliases_pick_and_cd ;;
        history|hist) _daliases_history ;;
        add|adddir) shift; _daliases_add "$@" ;;
        update|updadir) _daliases_update "$2" "$3" ;;
        del|deldir) _daliases_del "$2" ;;
        alias) _daliases_promote_alias "$2" "$3" ;;
        check|checkdir) _daliases_check ;;
        help|--help|-h) _daliases_help ;;
        *)
            if [[ -n "$(_daliases_get_path "$sub")" ]]; then
                _daliases_go_to "$sub"
            else
                echo "Unknown subcommand or shortcut: $sub" >&2; return 1
            fi
            ;;
    esac
}

alias aliasdir='_daliases_list'

if [[ -n "${BASH_VERSION-}" ]]; then
    _adir_complete() {
        local cur="${COMP_WORDS[COMP_CWORD]}" prev="${COMP_WORDS[COMP_CWORD-1]}"
        COMPREPLY=()
        if [[ "$COMP_CWORD" -eq 1 ]]; then
            mapfile -t COMPREPLY < <(compgen -W "list go pick jump history add update del alias check help $(_daliases_list_names)" -- "$cur")
            return 0
        fi
        case "$prev" in
            go|update|del|alias|list)
                mapfile -t COMPREPLY < <(compgen -W "$(_daliases_list_names)" -- "$cur")
                return 0 ;;
            add)
                [[ "$COMP_CWORD" -eq 3 ]] && mapfile -t COMPREPLY < <(compgen -d -- "$cur")
                return 0 ;;
        esac
        [[ "$COMP_CWORD" -eq 3 && "${COMP_WORDS[1]}" == "update" ]] && mapfile -t COMPREPLY < <(compgen -d -- "$cur")
        [[ "$COMP_CWORD" -eq 3 && "${COMP_WORDS[1]}" == "alias" ]] && mapfile -t COMPREPLY < <(compgen -W "on off" -- "$cur")
    }

    complete -F _adir_complete adir
elif [[ -n "${ZSH_VERSION-}" ]]; then
    # zsh-only syntax lives in eval so Bash never has to parse it.
    # Registered with compdef when the completion system is loaded (source this file after compinit).
    eval '
    _adir_zsh_complete() {
        local -a names
        names=(${(f)"$(_daliases_list_names)"})
        if (( CURRENT == 2 )); then
            compadd -- list go pick jump history add update del alias check help $names
            return
        fi
        case ${words[2]} in
            go|del|list) (( CURRENT == 3 )) && compadd -- $names ;;
            update) if (( CURRENT == 3 )); then compadd -- $names; else _path_files -/; fi ;;
            alias) if (( CURRENT == 3 )); then compadd -- $names; else compadd -- on off; fi ;;
            add) (( CURRENT == 3 )) || _path_files -/ ;;
        esac
    }
    if (( ${+functions[compdef]} )); then
        compdef _adir_zsh_complete adir
    else
        # compinit has not run yet: register on the first prompt instead
        _adir_late_compdef() {
            if (( ${+functions[compdef]} )); then
                compdef _adir_zsh_complete adir
                add-zsh-hook -d precmd _adir_late_compdef
            fi
        }
        autoload -Uz add-zsh-hook && add-zsh-hook precmd _adir_late_compdef
    fi
    '
fi

_daliases_load_shell_aliases
