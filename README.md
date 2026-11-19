# custom-daliases

A lightweight Bash directory-navigation tool (`adir`) for saving named directory shortcuts, jumping with tab completion or an interactive picker, checking for broken paths, and optionally promoting shortcuts to standalone shell aliases with built-in command conflict checks.

## Overview

Instead of scattering dozens of `cd` aliases across your shell dotfiles, `custom-daliases` stores shortcuts in a registry (`~/.config/custom-daliases/dirs.tsv` by default) and lets you jump to them through `adir`.

When you *do* want a shortcut to work as a direct command outside `adir`, you can opt in with `--alias` or `adir alias <name> on`. Before creating a standalone alias, `adir` checks existing builtins, keywords, functions, aliases, and `PATH` entries so it won't shadow existing Linux commands.

## Features

- **Any shortcut naming**: Name shortcuts whatever makes sense to you (such as `docs`, `work`, or `api-v2`).
- **Tab completion & interactive jumping**: Jump directly with `adir go <name>` (`Tab` completion supported) or pick interactively with `adir pick` / `adir jump`.
- **Safe opt-in shell aliases**: Keep shortcuts scoped to `adir` by default, or promote individual ones to standalone `cd` aliases with automatic command-conflict checks.
- **Health & path validation**: Verify directories exist and spot missing targets with `adir list` and `adir check`.
- **Configurable storage**: Override paths via `DALIASES_DB_FILE` and `DALIASES_SHELL_ALIASES_FILE` when needed.

## Installation

Works in Bash on Linux, WSL2, macOS, and Git Bash (requires `bash` and `python3`):

```bash
git clone https://github.com/Dasone/custom-daliases.git
cd custom-daliases
bash install.sh
source /etc/profile.d/custom-daliases.sh 2>/dev/null || source ~/.custom-daliases.sh
```

## Starting a new shell session
Running install.sh installs the script for future/login sessions. Run source in your current terminal session to load adir immediately. If a non-login interactive shell doesn't source /etc/profile.d/ automatically, you can also source it from ~/.bashrc.