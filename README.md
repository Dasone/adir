# custom-daliases

A lightweight directory-navigation tool (`adir`) for **Bash and Zsh**, for saving named directory shortcuts, jumping with tab completion or an interactive picker, checking for broken paths, and optionally promoting shortcuts to standalone shell aliases with built-in command conflict checks.

![adir demo](docs/demo.gif)

## Overview

Instead of scattering dozens of `cd` aliases across your shell dotfiles, `custom-daliases` stores shortcuts in a registry (`~/.config/custom-daliases/dirs.tsv` by default) and lets you jump to them through `adir`.

When you *do* want a shortcut to work as a direct command outside `adir`, you can opt in with `--alias` or `adir alias <name> on`. Before creating a standalone alias, `adir` checks existing builtins, keywords, functions, aliases, and `PATH` entries so it won't shadow existing Linux commands.

## Features

- **Simple shortcut naming**: Name shortcuts whatever makes sense to you (such as `docs`, `work`, or `api-v2`). Names must start with a letter or digit and may contain letters, digits, `_` and `-`.
- **Save the current directory**: `adir add <name> .` stores the absolute path of the directory you are in. Any relative path (`..`, `sub/dir`) is resolved to an absolute path when saved, in both `adir add` and `adir update`.
- **Quick jumping**: Jump with `adir <name>` (shorthand for `adir go <name>`), with tab completion for commands and shortcut names, or pick interactively with `adir pick` / `adir jump`.
- **Reserved command names**: Shortcut names that match an `adir` command (`history`, `list`, `go`, `add`, `update`, `del`, `alias`, `check`, `help`, `pick`, `jump`, and their legacy aliases) are rejected by `adir add`, so `adir <name>` is never ambiguous.
- **Navigation history**: `adir history` lists your last 10 visited shortcuts (name and path, newest at the bottom, no duplicates). Select one with `↑`/`↓` and press `Enter` to jump. Every `adir go`, `adir <name>` and `adir pick` is recorded.
- **Inspect a single shortcut**: `adir list <name>` shows its name, scope, and target.
- **Safe opt-in shell aliases**: Keep shortcuts scoped to `adir` by default, or promote individual ones to standalone `cd` aliases with automatic command-conflict checks.
- **Health & path validation**: Verify directories exist and spot missing targets with `adir list` and `adir check`.
- **Configurable storage**: Override paths via `DALIASES_DB_FILE` and `DALIASES_SHELL_ALIASES_FILE` when needed.

## Quick start

```bash
cd ~/code/my-project
adir add proj .        # save the current directory as "proj"
adir list proj         # show details for one shortcut
cd /
adir proj              # jump back (same as: adir go proj)
```

## Installation

Works in **Bash** (Linux, WSL2, macOS, Git Bash) and **Zsh**. Requires `python3`.

```bash
git clone https://github.com/Dasone/custom-daliases.git
cd custom-daliases
bash install.sh
source /etc/profile.d/custom-daliases.sh 2>/dev/null || source ~/.custom-daliases.sh
```

`install.sh` installs the script system-wide to `/etc/profile.d/` (or to `~/.custom-daliases.sh` when it can't write there) and adds a `source` line to your shell startup file, once, so every new terminal has `adir`:

- **Bash:** a line is added to `~/.bashrc`. This matters because `/etc/profile.d` is only read by *login* shells, while most terminal tabs start non-login interactive shells.
- **Zsh:** if you use zsh (`~/.zshrc` exists or zsh is your login shell), a line is added to `~/.zshrc`. Tab completion registers itself automatically, whether the line comes before or after `compinit`.

Run the `source` command above to start using `adir` in the terminal you installed from; new terminals load it by themselves.

## How it compares

Bookmarking directories under a name is a well-trodden idea, and there are good tools for it. `adir` is not the only way to do this; this is how it fits in:

| Tool | Approach | Shells |
| :--- | :--- | :--- |
| [`wd`](https://github.com/mfaerevaag/wd) | Named bookmarks ("warp directory") | zsh |
| [`goto`](https://github.com/iridakos/goto) | Named aliases for directories with completion | bash, zsh |
| [`bashmarks`](https://github.com/huyng/bashmarks) | Bookmarks via short commands | bash |
| [`zoxide`](https://github.com/ajeetdsouza/zoxide), [`autojump`](https://github.com/wting/autojump), [`z`](https://github.com/rupa/z) | Jump by *frecency* (how often and how recently you visit); no names to manage | bash, zsh, fish and more |
| **`adir`** | Named bookmarks + recent history + opt-in real aliases | bash, zsh |

If you want to type a few letters of a path and land in the most-used match, a frecency tool like `zoxide` is a better fit, and it combines well with `adir`. If you prefer explicit names that you control, `adir` is aimed at you. What it adds on top of plain named bookmarks:

- **Safe standalone aliases:** promote a shortcut to a real shell alias, with a check that it won't shadow a builtin, keyword, function, alias or `PATH` command.
- **Unambiguous `adir <name>`:** the names of `adir`'s own commands are reserved, so a shortcut can never hide a command.
- **Arrow-key history:** `adir history` shows your last 10 visited shortcuts with no fuzzy-finder dependency.
- **Save where you are:** `adir add <name> .` stores the absolute path of the current directory.
- **Plain-text storage:** shortcuts live in a small tab-separated file you can read, edit and back up.

## License

MIT, see [LICENSE](LICENSE).
