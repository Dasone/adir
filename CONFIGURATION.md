# Configuration

By default, files live under `${XDG_CONFIG_HOME:-$HOME/.config}/custom-daliases`:

- `dirs.tsv` — Stores shortcut names, target paths, and alias promotion status (`DALIASES_DB_FILE`).
- `shell_aliases.sh` — Generated standalone shell aliases for promoted shortcuts (`DALIASES_SHELL_ALIASES_FILE`).

## Overriding Storage Locations

```bash
export DALIASES_DB_FILE="$HOME/.config/custom-daliases/custom-dirs.tsv"
export DALIASES_SHELL_ALIASES_FILE="$HOME/.config/custom-daliases/custom-aliases.sh"