# custom-daliases

Manage, validate, pick, and jump between `*dir` directory shortcuts in Bash with tab completion and health checks (`adir`), plus an optional Hyper click add-on (`hyper-adir-click`).

## Standalone Installation (Linux, WSL, macOS Bash, Git Bash)

Installs the full shell helpers (`adir`, `adddir`, `updadir`, `deldir`, `checkdir`, `daliases`, and tab completion):

```bash
git clone [https://github.com/Dasone/custom-daliases.git](https://github.com/Dasone/custom-daliases.git)
cd custom-daliases
bash install.sh
source /etc/profile.d/custom-daliases.sh 2>/dev/null || source ~/.custom-daliases.sh
```

## Optional Add-On: Hyper Click Plugin (`hyper-adir-click`)

`hyper-adir-click` is a **separate, optional add-on**—it does **not** install the `custom-daliases` Bash functions or aliases on its own. Instead, when you click a `*dir` alias name printed in Hyper, it sends `<aliasName>\r` to your active terminal session so a matching shell alias/command can `cd` there.

1. Copy `hyper-plugin/hyper-adir-click` into Hyper's local plugins directory (`~/.hyper_plugins/local/hyper-adir-click` or `%APPDATA%\Hyper\.hyper_plugins\local\hyper-adir-click`).
2. Add `"hyper-adir-click"` to `localPlugins` in `.hyper.js`.
3. Reload Hyper (`Ctrl+Shift+R` or `Cmd+Shift+R`) and click a `*dir` alias name.
