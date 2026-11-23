# Configuration

By default, files live under `${XDG_CONFIG_HOME:-$HOME/.config}/adir`:

- `dirs.tsv` — Stores shortcut names, target paths, and alias promotion status (`ADIR_DB_FILE`).
- `shell_aliases.sh` — Generated standalone shell aliases for promoted shortcuts (`ADIR_SHELL_ALIASES_FILE`).
- `history` — The last 10 visited shortcut names, oldest first (`ADIR_HISTORY_FILE`). Defaults to a file next to `dirs.tsv`.

## Overriding Storage Locations

```bash
export ADIR_DB_FILE="$HOME/.config/adir/custom-dirs.tsv"
export ADIR_SHELL_ALIASES_FILE="$HOME/.config/adir/custom-aliases.sh"
export ADIR_HISTORY_FILE="$HOME/.config/adir/history"
