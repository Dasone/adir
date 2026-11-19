# custom-daliases

Manage, validate, pick, and jump between `*dir` directory shortcuts in Bash with tab completion, health checks (`adir`), and an optional Hyper click-to-jump plugin.

## Standalone Installation (Linux, WSL, macOS Bash, Git Bash)

```bash
git clone https://github.com/Dasone/custom-daliases.git
cd custom-daliases
bash install.sh
source /etc/profile.d/custom-daliases.sh 2>/dev/null || source ~/.custom-daliases.sh
```

## Optional Hyper Plugin (`hyper-adir-click`)

1. Copy `hyper-plugin/hyper-adir-click` into Hyper's local plugins directory (`~/.hyper_plugins/local/hyper-adir-click` or `%APPDATA%\Hyper\.hyper_plugins\local\hyper-adir-click`).
2. Add `"hyper-adir-click"` to `localPlugins` in `.hyper.js`.
3. Reload Hyper and `Alt + Click` any `*dir` alias name.
