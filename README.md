# Claude Code TMUX Status Bar

A tmux config tuned for Claude Code workflows — status bar with session/window context, quick window management, and sane defaults.

## Install

```sh
cp tmux.conf ~/.tmux.conf
tmux source-file ~/.tmux.conf
```

## Key Bindings (Prefix = Ctrl+Space)

| Key | Action |
|-----|--------|
| `Prefix + P` | Create preset layout: Claude / Server / Docs windows |
| `Prefix + n` | New named window (prompts for name, opens in current dir) |
| `Prefix + T` | Rename current window |
| `Prefix + s` | Jump anywhere — sessions, windows, panes (choose-tree) |
| `Prefix + X` | Kill current window (with confirm) |
| `Prefix + r` | Reload config |

## Status Bar

Purple bar at top shows `session:window_index:window_name`. No window list clutter — just where you are.

## Other Notable Defaults

- Mouse on
- 200k line scrollback
- vi copy mode
- 1-based window indexing, auto-renumber on close
- Truecolor support
