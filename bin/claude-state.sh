#!/usr/bin/env bash
# claude-state.sh — Write Claude Code session state to a per-pane JSON file.
#
# State is keyed by $TMUX_PANE (e.g. %3) so multiple Claude sessions in
# different windows don't stomp each other.

set -euo pipefail

_PANE_ID="${TMUX_PANE:-global}"
CLAUDE_STATE_FILE="${CLAUDE_STATE_FILE:-/tmp/claude-state-${_PANE_ID}.json}"

_valid_states="idle working waiting_input error stopped"

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

_default_message_for_state() {
  case "$1" in
    idle)          echo "Idle" ;;
    working)       echo "Working..." ;;
    waiting_input) echo "Waiting for input" ;;
    error)         echo "Error" ;;
    stopped)       echo "Stopped" ;;
    *)             echo "$1" ;;
  esac
}

claude_state_set() {
  local state="${1:?Usage: claude_state_set <state> [message]}"
  local message="${2:-$(_default_message_for_state "$state")}"

  case " $_valid_states " in
    *" $state "*) ;;
    *)
      echo "claude-state: unknown state '$state'" >&2
      echo "claude-state: valid states: $_valid_states" >&2
      return 1
      ;;
  esac

  _claude_state_write_json "$state" "$message"
}

claude_state_stop() {
  _claude_state_write_json "stopped" "${1:-Stopped}"
}

claude_state_read() {
  if [[ -f "$CLAUDE_STATE_FILE" ]]; then
    cat "$CLAUDE_STATE_FILE"
  else
    echo '{"state":"unknown","message":"No state","timestamp":"","pid":0}'
  fi
}

# Tiny JSON parser — no jq dependency.
claude_state_get_field() {
  local field="${1:?Usage: claude_state_get_field <field>}"
  claude_state_read | sed -n "s/.*\"$field\"[[:space:]]*:[[:space:]]*\"\{0,1\}\([^\",$]*\)\"\{0,1\}.*/\1/p" | head -1
}
