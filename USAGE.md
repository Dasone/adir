# Usage & Examples

## Commands

| Command | Description |
| :--- | :--- |
| `adir` / `adir list` | List saved shortcuts, scope (`adir` vs `alias`), and target paths (highlighting missing paths) |
| `adir go <name>` | Jump (`cd`) directly to a shortcut (`Tab` completion supported) |
| `adir pick` / `adir jump` | Open an interactive numbered menu to choose a shortcut and `cd` into it |
| `adir add <name> <path> [--alias]` | Add a shortcut, optionally promoting it to a standalone shell alias |
| `adir update <name> <path>` | Update the target directory of an existing shortcut |
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

# 4. Check for broken/missing directories
adir check