# claude-tmux — Dev Context

## How users actually run this

The primary use case is **multiple Ghostty windows, each containing its own tmux session**. There is no window list. Each physical terminal window IS one tmux session with one Claude Code instance running in it.

```
[Ghostty window 1]     [Ghostty window 2]     [Ghostty window 3]
  tmux session: waldo    tmux session: waldo    tmux session: clockwork
  1 pane, Claude running 1 pane, Claude running 1 pane, shell only
  [yellow bar]           [red/orange bar]       [pink bar — default]
```

## Critical: session-level vs global tmux style

**Always use `tmux set-option status-style` (no `-g`) for color changes.**

- `set-option -g status-style` = global, affects ALL sessions on the tmux server → wrong, all windows change color together
- `set-option status-style` (no `-g`) = session-scoped → correct, each window changes independently

## The pink base style is intentional

The global default (`set -g status-style bg=colour171` in the user's tmux.conf) is pink. We never override the global. This means:

- **Pink bar** = pure shell window, no Claude hooks have fired → useful signal
- **Colored bar** = Claude session active in this window

When a Claude session ends, the session-level style stays (e.g. green = done). The pink only shows for windows where Claude has never run or after a full tmux restart.

## Color scheme

| State | Bar color | When |
|-------|-----------|------|
| working | Yellow | PreToolUse / PostToolUse |
| waiting | Red/orange | Notification (needs input) |
| done | Green | Stop (completed) |
| default | Pink | No Claude session / global default |

## Don't assume a window list exists

The status bar may only show the current session name + a right-side indicator. Don't design features that depend on a visible window list.
