# Shared *dir aliases (available to root and all users)

# List active *dir aliases in a clean table
_daliases_pick_and_cd() {
    local entries=()
    local line name target expanded

    while IFS=$'\t' read -r name target; do
        [[ -n "$name" ]] && entries+=("${name}"$'\t'"${target}")
    done < <(
        python3 - <<'PYEOF'
import re
from pathlib import Path

pattern = re.compile(r"^\s*alias\s+([^\s=]+dir)=['\"]?cd\s+([^'\"]+)['\"]?")
for line in Path("/etc/profile.d/custom-daliases.sh").read_text().splitlines():
    m = pattern.match(line)
    if m:
        print(f"{m.group(1)}\t{m.group(2)}")
PYEOF
    )

    if [[ "${#entries[@]}" -eq 0 ]]; then
        echo "No *dir aliases found."
        return 1
    fi

    local chosen_target=""
    if command -v fzf >/dev/null 2>&1; then
        local selected
        selected=$(printf '%s\n' "${entries[@]}" | fzf --height=~40% --reverse --prompt="Jump to *dir> ") || return 1
        chosen_target="${selected#*$'\t'}"
    else
        printf '%b\n' "\033[1;36mSelect a directory alias to jump to (Enter/number, q to cancel):\033[0m"
        local i=1 item n t
        for item in "${entries[@]}"; do
            n="${item%%$'\t'*}"
            t="${item#*$'\t'}"
            printf '  %2d) %-14s -> %s\n' "$i" "$n" "$t"
            i=$((i + 1))
        done

        local choice
        printf '> '
        read -r choice
        [[ -z "$choice" || "$choice" == "q" || "$choice" == "Q" ]] && return 1

        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#entries[@]} )); then
            chosen_target="${entries[$((choice - 1))]#*$'\t'}"
        else
            local found=""
            for item in "${entries[@]}"; do
                n="${item%%$'\t'*}"
                t="${item#*$'\t'}"
                if [[ "$n" == "$choice" ]]; then
                    found="$t"
                    break
                fi
            done
            if [[ -z "$found" ]]; then
                printf '%b\n' "\033[1;31mInvalid selection: ${choice}\033[0m"
                return 1
            fi
            chosen_target="$found"
        fi
    fi

    expanded=$(eval echo "$chosen_target" 2>/dev/null) || expanded="$chosen_target"
    if [[ ! -d "$expanded" ]]; then
        printf '%b\n' "\033[1;31mTarget directory does not exist: ${chosen_target}\033[0m"
        return 1
    fi

    cd "$expanded" || return 1
}

_daliases_go_to() {
    local target_name="$1"
    if [[ -z "$target_name" ]]; then
        echo "Usage: adir go <alias>" >&2
        return 1
    fi

    local raw_target=""
    while IFS=$'\t' read -r name target; do
        if [[ "$name" == "$target_name" ]]; then
            raw_target="$target"
            break
        fi
    done < <(
        python3 - <<'PYEOF'
import re
from pathlib import Path

src = Path("/etc/profile.d/custom-daliases.sh")
if not src.exists():
    src = Path.home() / ".custom-daliases.sh"
if not src.exists():
    raise SystemExit(0)

pattern = re.compile(r"^\s*alias\s+([^\s=]+)=['\"]?cd\s+([^'\"]+)['\"]?")
for line in src.read_text(encoding="utf-8", errors="ignore").splitlines():
    m = pattern.match(line)
    if m:
        print(f"{m.group(1)}\t{m.group(2)}")
PYEOF
    )

    if [[ -z "$raw_target" ]]; then
        local alias_cmd
        alias_cmd=$(alias "$target_name" 2>/dev/null || true)
        if [[ "$alias_cmd" =~ cd[[:space:]]+[\'\"]?([^\'\"[:space:]]+) ]]; then
            raw_target="${BASH_REMATCH[1]}"
        fi
    fi

    if [[ -z "$raw_target" ]]; then
        echo "Unknown alias: $target_name" >&2
        return 1
    fi

    local expanded
    expanded=$(eval echo "$raw_target" 2>/dev/null) || expanded="$raw_target"
    if [[ ! -d "$expanded" ]]; then
        echo "Target directory does not exist: $raw_target" >&2
        return 1
    fi

    cd "$expanded" || return 1
}

_daliases_list_alias_names() {
    python3 - <<'PYEOF'
import re
from pathlib import Path

src = Path("/etc/profile.d/custom-daliases.sh")
if not src.exists():
    src = Path.home() / ".custom-daliases.sh"
if not src.exists():
    raise SystemExit(0)

pattern = re.compile(r"^\s*alias\s+([^\s=]+dir)=")
seen = []
for line in src.read_text(encoding="utf-8", errors="ignore").splitlines():
    m = pattern.match(line)
    if m and m.group(1) not in seen:
        seen.append(m.group(1))

for name in sorted(seen):
    print(name)
PYEOF
}

daliases() {
    if [[ "$1" == "--pick" || "$1" == "-p" || "$1" == "pick" ]]; then
        _daliases_pick_and_cd
        return $?
    fi

    if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "help" ]]; then
        cat <<'HELPEOF'
Manage, validate, pick, and jump between *dir directory shortcuts in Bash
with tab completion and health checks (adir).

Directory Aliases (*dir) — Quick Reference
-----------------------------------------
Unified command (adir):
  adir                  Show sorted *dir table (same as 'adir list')
  adir list             Show sorted *dir table (missing paths in red)
  adir go <alias>       Jump (cd) directly to a *dir alias target
  adir pick / jump      Interactively select a *dir shortcut and cd into it
  adir add <name> <path>
                        Add a new *dir alias and activate in current shell
  adir update <name> <path>
                        Update an existing *dir alias target path
  adir del <name>       Remove an existing *dir cd shortcut
  adir check            Run read-only diagnostics on setup and paths
  adir help             Show this help message

  (Long subcommand forms daliases, aliasdir, adddir, updadir, deldir,
   and checkdir are also accepted after 'adir'.)

Standalone commands:
  daliases / aliasdir   Show sorted *dir table
  adddir <name> <path>  Create a new *dir shortcut (target must exist)
  updadir <name> <path> Update an existing *dir shortcut (target must exist)
  deldir <name>         Remove a *dir cd shortcut (protects helper aliases)
  checkdir              Verify functions, tab completion, and target paths

How it loads:
  Sourced automatically via /etc/profile.d/custom-daliases.sh or ~/.custom-daliases.sh.
HELPEOF
        return 0
    fi

    python3 - <<'PYEOF'
import os
import re
from pathlib import Path

rows = []
pattern = re.compile(r"^\s*alias\s+([^=\s]+dir)=['\"]?cd\s+([^'\"]+)['\"]?")
for line in Path('/etc/profile.d/custom-daliases.sh').read_text().splitlines():
    m = pattern.match(line)
    if m:
        rows.append((m.group(1), m.group(2)))

rows.sort(key=lambda r: r[0])
alias_w = max([len('ALIAS'), len('----')] + [len(a) for a, _ in rows])
path_w = max([len('PATH'), len('----')] + [len(p) for _, p in rows])
gap = '    '

hdr_a = f"\033[1;36m{'ALIAS':<{alias_w}}\033[0m"
hdr_p = f"\033[1;36m{'PATH':<{path_w}}\033[0m"
print(f"{hdr_a}{gap}{hdr_p}")
print(f"{'-' * alias_w}{gap}{'-' * path_w}")
for name, target in rows:
    expanded = os.path.expandvars(os.path.expanduser(target))
    exists = Path(expanded).is_dir()
    if exists:
        print(f"{name:<{alias_w}}{gap}{target}")
    else:
        colored_path = f"\033[1;31m{target}\033[0m"
        print(f"{name:<{alias_w}}{gap}{colored_path}")
PYEOF
}

# Add a new *dir alias and load it immediately: adddir <name> <target_path>

# Remove an existing *dir alias: deldir <name>

# Update an existing *dir alias path (or add it if missing): updadir <name> <new_target_path>
adddir() {
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        cat <<'HELPEOF'
Usage: adddir <name_ending_in_dir> <target_path>

Create a new *dir shortcut in /etc/profile.d/custom-daliases.sh and
activate it immediately in the current shell. Fails if the target
directory does not exist.

Example:
  adddir myprojdir /path/to/dir
HELPEOF
        return 0
    fi

    local name="$1"
    local target="$2"
    local file="/etc/profile.d/custom-daliases.sh"

    if [[ -z "$name" || -z "$target" ]]; then
        echo "Usage: adddir <name_ending_in_dir> <target_path>"
        return 1
    fi

    if [[ ! "$name" =~ ^.+dir$ ]]; then
        echo "Error: alias name must have text before 'dir' (e.g., projdir)"
        return 1
    fi

    local expanded
    expanded=$(eval echo "$target" 2>/dev/null) || expanded="$target"
    if [[ ! -d "$expanded" ]]; then
        printf '\033[1;31mError: target directory does not exist: %s\033[0m\n' "$target"
        return 1
    fi

    if grep -qE "^[[:space:]]*alias[[:space:]]+${name}=" "$file"; then
        echo "Already exists: $name (use 'updadir $name <path>' to change it)"
        return 1
    fi

    echo "alias ${name}='cd ${target}'" >> "$file"
    alias "${name}=cd ${target}"
    echo "Added: alias ${name}='cd ${target}'"
}

deldir() {
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        cat <<'HELPEOF'
Usage: deldir <name_ending_in_dir>

Remove an existing *dir cd shortcut from /etc/profile.d/custom-daliases.sh
and unalias it in the current shell. Refuses non-cd helper aliases like
aliasdir.

Example:
  deldir ucpdmdir
HELPEOF
        return 0
    fi

    local name="$1"
    local file="/etc/profile.d/custom-daliases.sh"

    if [[ -z "$name" ]]; then
        echo "Usage: deldir <name_ending_in_dir>"
        return 1
    fi

    if [[ ! "$name" =~ ^.+dir$ ]]; then
        echo "Error: alias name must end with 'dir' (e.g., projdir)"
        return 1
    fi

    local match
    match=$(grep -E "^[[:space:]]*alias[[:space:]]+${name}=" "$file" | head -n 1)
    if [[ -z "$match" ]]; then
        echo "Not found: $name"
        return 1
    fi

    local cd_re='=[[:space:]]*['"'"']?cd[[:space:]]+'
    if [[ ! "$match" =~ $cd_re ]]; then
        printf '%b\n' "\033[1;31mError: ${name} is not a cd directory shortcut; refusing to remove\033[0m"
        return 1
    fi

    sed -i -E "/^[[:space:]]*alias[[:space:]]+${name}=/d" "$file"
    unalias "$name" 2>/dev/null || true
    echo "Removed: $name"
}

adir() {
    local sub="${1:-list}"

    case "$sub" in
        help|--help|-h)
            daliases --help
            ;;
        pick|jump)
            shift 2>/dev/null || true
            _daliases_pick_and_cd
            ;;
        go)
            _daliases_go_to "$2"
            ;;
        list|daliases|aliasdir)
            shift 2>/dev/null || true
            daliases "$@"
            ;;
        add|adddir)
            shift
            adddir "$@"
            ;;
        update|updadir)
            shift
            updadir "$@"
            ;;
        del|deldir)
            shift
            deldir "$@"
            ;;
        check|checkdir)
            shift
            checkdir "$@"
            ;;
        *)
            printf '%b\n' "\033[1;31mUnknown subcommand: ${sub}\033[0m"
            echo "Run 'adir help' to see available subcommands."
            return 1
            ;;
    esac
}

_adir_complete() {
    local cur prev
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    local subs="list daliases aliasdir go pick jump add adddir update updadir del deldir check checkdir help"

    if [[ "$COMP_CWORD" -eq 1 ]]; then
        COMPREPLY=( $(compgen -W "$subs" -- "$cur") )
        return 0
    fi

    if [[ "$COMP_CWORD" -eq 2 && "$prev" == "go" ]]; then
        local names
        names=$(_daliases_list_alias_names)
        COMPREPLY=( $(compgen -W "$names" -- "$cur") )
        return 0
    fi

    case "$prev" in
        update|updadir|del|deldir)
            local names
            names=$(_daliases_list_alias_names)
            COMPREPLY=( $(compgen -W "$names" -- "$cur") )
            return 0
            ;;
        add|adddir)
            if [[ "$COMP_CWORD" -eq 3 ]]; then
                COMPREPLY=( $(compgen -d -- "$cur") )
                return 0
            fi
            ;;
    esac

    if [[ "$COMP_CWORD" -eq 3 && ( "${COMP_WORDS[1]}" == "update" || "${COMP_WORDS[1]}" == "updadir" ) ]]; then
        COMPREPLY=( $(compgen -d -- "$cur") )
        return 0
    fi
}

complete -o filenames -F _adir_complete adir
