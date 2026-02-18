#!/usr/bin/env bash
# tmux-claude-status.sh — Read per-pane Claude state and update the tmux status bar.
#
# Called by tmux status-right with the current pane ID so each window
# reflects its own Claude session independently.
#
# tmux config:
#   set -g status-interval 2
#   set -g status-right '#(~/.claude-tmux/bin/tmux-claude-status.sh #{pane_id})'

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PANE_ID="${1:-${TMUX_PANE:-global}}"
export CLAUDE_STATE_FILE="/tmp/claude-state-${PANE_ID}.json"

source "$SCRIPT_DIR/claude-state.sh"

_state_bg() {
  case "$1" in
    idle)          echo "colour235" ;;
    working)       echo "colour33"  ;;
    waiting_input) echo "colour214" ;;
    error)         echo "colour196" ;;
    stopped)       echo "colour240" ;;
    *)             echo "colour236" ;;
  esac
}

_state_fg() {
  case "$1" in
    idle)          echo "colour245" ;;
    working)       echo "colour255" ;;
    waiting_input) echo "colour233" ;;
    error)         echo "colour255" ;;
    stopped)       echo "colour250" ;;
    *)             echo "colour242" ;;
  esac
}

_state_icon() {
  case "$1" in
    idle)          echo "○" ;;
    working)       echo "●" ;;
    waiting_input) echo "◆" ;;
    error)         echo "✖" ;;
    stopped)       echo "□" ;;
    *)             echo "?" ;;
  esac
}

state="$(claude_state_get_field state)"
message="$(claude_state_get_field message)"

bg="$(_state_bg "$state")"
fg="$(_state_fg "$state")"
icon="$(_state_icon "$state")"

if [[ -n "${TMUX:-}" ]]; then
  tmux set-option -g status-style "bg=$bg,fg=$fg" 2>/dev/null || true
fi

echo " ${icon} ${message} "
