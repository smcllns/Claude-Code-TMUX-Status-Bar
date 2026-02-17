# claude-tmux

Color-coded tmux status bar that tracks Claude Code session state per window.

Each tmux window with a Claude Code session shows its own indicator — green while working, amber when waiting for your input, grey when idle. Switch windows and the status bar updates instantly.

```
 main:1:Claude  ● Running command...          ← blue, Claude is working
 main:2:Server  ◆ Question for you...         ← amber, needs your input
 main:3:Docs    ○ Ready                       ← grey, idle
```

## States

| State | Color | Icon | When |
|-------|-------|------|------|
| `working` | Blue | `●` | Using a tool (Bash, Edit, Read, etc.) |
| `waiting_input` | Amber | `◆` | Needs your input or confirmation |
| `idle` | Dark grey | `○` | Finished, ready for next prompt |
| `stopped` | Medium grey | `□` | Session exited |
| `error` | Red | `✖` | Error state |

## How it works

```
Claude Code hooks → claude-hooks.sh → /tmp/claude-state-{pane_id}.json
                                                    ↓
                              tmux status-right polls every 2s
                                                    ↓
                                        Status bar color + text
```

State is keyed by `$TMUX_PANE` (e.g. `%3`), which tmux sets automatically. Multiple Claude sessions in different windows never interfere with each other.

## Install

```sh
git clone https://github.com/smcllns/Claude-Code-TMUX-Status-Bar ~/.claude-tmux-src
~/.claude-tmux-src/install.sh
```

Then add the hooks from `examples/claude-settings.jsonc` to your `~/.claude/settings.json` (merge into the existing `hooks` object).

Reload tmux:
```sh
tmux source-file ~/.tmux.conf
```

## Manual install

1. Copy `bin/` to `~/.claude-tmux/bin/` and make scripts executable
2. Add to `~/.tmux.conf`:
   ```
   set -g status-interval 2
   set -g status-right '#(~/.claude-tmux/bin/tmux-claude-status.sh #{pane_id})'
   ```
3. Add hooks to `~/.claude/settings.json` — see `examples/claude-settings.jsonc`

## Files

```
bin/
  claude-state.sh          # Core library: writes per-pane state JSON
  claude-hooks.sh          # Claude Code hook entry points
  tmux-claude-status.sh    # Reads state, sets tmux color, outputs status text
examples/
  claude-settings.jsonc    # Hook config to merge into ~/.claude/settings.json
  tmux.conf                # tmux snippet to add to ~/.tmux.conf
install.sh                 # Installer
```

## Extending

The state file at `/tmp/claude-state-{pane_id}.json` is a simple JSON interface:

```json
{
  "state": "working",
  "message": "Running command...",
  "timestamp": "2026-02-17T12:00:00Z",
  "pid": 12345
}
```

Other consumers you could build on top:
- macOS menu bar widget (SwiftBar/xbar)
- Desktop notifications on `waiting_input`
- Web dashboard polling the JSON files
