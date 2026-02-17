#!/usr/bin/env bash
# tmux-claude-status.sh — Read per-pane Claude state and update the tmux status bar.
#
# Called by tmux status-right with the current pane ID so each window
# reflects its own Claude session independently.
#
# tmux config (add to ~/.tmux.conf):
#   set -g status-interval 2
#   set -g status-right '#(~/.claude-tmux/bin/tmux-claude-status.sh #{pane_id})'

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Accept pane_id as first arg (passed from tmux as #{pane_id}, e.g. %3).
# Falls back to $TMUX_PANE or "global".
PANE_ID="${1:-${TMUX_PANE:-global}}"
export CLAUDE_STATE_FILE="/tmp/claude-state-${PANE_ID}.json"

source "$SCRIPT_DIR/claude-state.sh"

# ── Colors (tmux colour codes) ─────────────────────────────────────────
declare -A STATE_BG STATE_FG STATE_ICON

STATE_BG[idle]="colour235"          # dark grey
STATE_FG[idle]="colour245"          # light grey
STATE_ICON[idle]="○"

STATE_BG[working]="colour33"        # blue
STATE_FG[working]="colour255"       # white
STATE_ICON[working]="●"

STATE_BG[waiting_input]="colour214" # amber
STATE_FG[waiting_input]="colour233" # near-black
STATE_ICON[waiting_input]="◆"

STATE_BG[error]="colour196"         # red
STATE_FG[error]="colour255"         # white
STATE_ICON[error]="✖"

STATE_BG[stopped]="colour240"       # medium grey
STATE_FG[stopped]="colour250"       # light grey
STATE_ICON[stopped]="□"

STATE_BG[unknown]="colour236"
STATE_FG[unknown]="colour242"
STATE_ICON[unknown]="?"

# ── Main ───────────────────────────────────────────────────────────────

state="$(claude_state_get_field state)"
message="$(claude_state_get_field message)"

bg="${STATE_BG[$state]:-${STATE_BG[unknown]}}"
fg="${STATE_FG[$state]:-${STATE_FG[unknown]}}"
icon="${STATE_ICON[$state]:-${STATE_ICON[unknown]}}"

# Set the status bar background color for the whole bar.
# Since this runs in the context of the active pane, it reflects the
# current window's Claude session.
if [[ -n "${TMUX:-}" ]]; then
  tmux set-option -g status-style "bg=$bg,fg=$fg" 2>/dev/null || true
fi

# Output the status segment text (tmux displays this in status-right).
echo " ${icon} ${message} "
