# Usage & Examples

## Commands

| Command | Description |
| :--- | :--- |
| `adir` / `adir list` | List saved shortcuts, scope (`adir` vs `alias`), and target paths (highlighting missing paths) |
| `adir list <name>` | Show details (shortcut, scope, target) for a single shortcut |
| `adir go <name>` | Jump (`cd`) directly to a shortcut (`Tab` completion supported) |
| `adir <name>` | Shorthand for `adir go <name>`; built-in command names always take precedence |
| `adir history` | Show your last 10 visited shortcuts (newest at the bottom, no duplicates). Move with `↑`/`↓` (or `j`/`k`), `Enter` to jump there, `q`/`Esc` to cancel |
| `adir pick` / `adir jump` | Open an interactive numbered menu to choose a shortcut and `cd` into it |
| `adir add <name> <path> [--alias]` | Add a shortcut, optionally promoting it to a standalone shell alias. `.` or any relative path is saved as an absolute path (e.g. `adir add here .`). Names of `adir` commands are reserved and rejected |
| `adir update <name> <path>` | Update the target directory of an existing shortcut. Like `add`, a relative path such as `.` is saved as an absolute path |
| `adir del <name>` | Remove a shortcut and any standalone shell alias created for it |
| `adir alias <name> [on\|off]` | Enable or disable a standalone shell alias outside `adir` (with conflict checking) |
| `adir check` | Run diagnostics on the registry/alias files and count missing target directories |
| `adir help` | Display formatted help and usage examples |

## Examples

```bash
# 1. Create a shortcut scoped to adir (no global shell alias created)
adir add docs ~/Documents
adir go docs

# 2. Create a shortcut and promote it to a standalone shell alias (if no command conflict exists)
adir add proj ~/code/my-project --alias
proj

# 3. Promote an existing shortcut later or disable its standalone alias
adir alias docs on
adir alias proj off

# 4. Save the directory you are currently in
cd /root/work/project/myproject
adir add myproject .
adir list myproject
# Shortcut: myproject
# Shell: adir
# Target: "/root/work/project/myproject"

# 5. Jump without "go"
adir myproject

# 6. Reserved names are rejected
adir add list .
# 'list' is a reserved adir command and cannot be used as a shortcut name.

# 7. Revisit a recent shortcut: arrow keys to select, Enter to jump
adir history

# 8. Check for broken/missing directories
adir check
