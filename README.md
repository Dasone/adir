# custom-daliases

Manage, validate, pick, and jump between `*dir` directory shortcuts in Bash with tab completion and health checks (`adir`).

## Installation (Linux, WSL, macOS Bash, Git Bash)

```bash
git clone [https://github.com/Dasone/custom-daliases.git](https://github.com/Dasone/custom-daliases.git)
cd custom-daliases
bash install.sh
source /etc/profile.d/custom-daliases.sh 2>/dev/null || source ~/.custom-daliases.sh
```

## Usage

- `adir go <alias>` — Jump directly to a `*dir` shortcut with `Tab` completion
- `adir pick` / `adir jump` — Interactively select a `*dir` shortcut
- `adir list` — Display sorted `*dir` shortcuts and flag missing paths
- `adir add <name> <path>` / `adir update <name> <path>` / `adir del <name>` — Manage shortcuts
- `adir check` — Run diagnostics on your setup and target directories
