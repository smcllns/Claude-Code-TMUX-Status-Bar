#!/usr/bin/env bash
# claude-state.sh — Write Claude Code session state to a per-pane JSON file.
#
# State is keyed by $TMUX_PANE (e.g. %3) so multiple Claude sessions in
# different windows don't stomp each other.
#
# States:
#   idle           — Claude is running but not actively doing anything
#   working        — Claude is generating output or using tools
#   waiting_input  — Claude is waiting for user input or confirmation
#   error          — An error occurred
#   stopped        — Claude Code process has exited
#
# Usage:
#   source bin/claude-state.sh
#   claude_state_set working "Running tests..."
#   claude_state_set waiting_input "Confirm file edit?"
#   claude_state_stop

set -euo pipefail

# Key state file by TMUX_PANE so each window has independent state.
_PANE_ID="${TMUX_PANE:-global}"
CLAUDE_STATE_FILE="${CLAUDE_STATE_FILE:-/tmp/claude-state-${_PANE_ID}.json}"

declare -A _CLAUDE_VALID_STATES=(
  [idle]="Idle"
  [working]="Working..."
  [waiting_input]="Waiting for input"
  [error]="Error"
  [stopped]="Stopped"
)

_claude_state_timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

_claude_state_write_json() {
  local state="$1"
  local message="$2"
  local ts
  ts="$(_claude_state_timestamp)"

  printf '{\n  "state": "%s",\n  "message": "%s",\n  "timestamp": "%s",\n  "pid": %d\n}\n' \
    "$state" "$message" "$ts" "$$" > "$CLAUDE_STATE_FILE"
}

claude_state_set() {
  local state="${1:?Usage: claude_state_set <state> [message]}"
  local message="${2:-${_CLAUDE_VALID_STATES[$state]:-$state}}"

  if [[ -z "${_CLAUDE_VALID_STATES[$state]+x}" ]]; then
    echo "claude-state: unknown state '$state'" >&2
    echo "claude-state: valid states: ${!_CLAUDE_VALID_STATES[*]}" >&2
    return 1
  fi

  _claude_state_write_json "$state" "$message"
}

claude_state_stop() {
  local message="${1:-Stopped}"
  _claude_state_write_json "stopped" "$message"
}

claude_state_read() {
  if [[ -f "$CLAUDE_STATE_FILE" ]]; then
    cat "$CLAUDE_STATE_FILE"
  else
    echo '{"state":"unknown","message":"No state","timestamp":"","pid":0}'
  fi
}

# Tiny JSON parser — no jq dependency needed for simple flat objects.
claude_state_get_field() {
  local field="${1:?Usage: claude_state_get_field <field>}"
  claude_state_read | sed -n "s/.*\"$field\"[[:space:]]*:[[:space:]]*\"\{0,1\}\([^\",$]*\)\"\{0,1\}.*/\1/p" | head -1
}
