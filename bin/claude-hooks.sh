#!/usr/bin/env bash
# claude-hooks.sh — Hook entry points for Claude Code's hook system.
#
# Translates Claude Code events into state updates in the per-pane JSON file.
# $TMUX_PANE is set automatically by tmux, so each window tracks independently.
#
# Wire up in ~/.claude/settings.json — see examples/claude-settings.jsonc.
# Path should point to wherever you installed this repo (default: ~/.claude-tmux).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/claude-state.sh"

EVENT="${1:?Usage: claude-hooks.sh <event> (pre-tool|post-tool|notification|stop|session-start|session-end)}"

INPUT=""
if [[ ! -t 0 ]]; then
  INPUT="$(cat)"
fi

get_json_field() {
  local field="$1"
  echo "$INPUT" | sed -n "s/.*\"$field\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -1
}

case "$EVENT" in
  pre-tool)
    tool_name="$(get_json_field tool_name)"
    case "$tool_name" in
      Bash)            claude_state_set working "Running command..." ;;
      Read|Glob)       claude_state_set working "Reading files..." ;;
      Edit|Write)      claude_state_set working "Editing files..." ;;
      Grep)            claude_state_set working "Searching code..." ;;
      WebFetch|WebSearch) claude_state_set working "Fetching web..." ;;
      Task)            claude_state_set working "Running sub-agent..." ;;
      AskUserQuestion) claude_state_set waiting_input "Question for you..." ;;
      *)               claude_state_set working "Using ${tool_name:-tool}..." ;;
    esac
    ;;

  post-tool)
    claude_state_set working "Thinking..."
    ;;

  notification)
    title="$(get_json_field title)"
    claude_state_set waiting_input "${title:-Needs attention}"
    ;;

  stop)
    claude_state_set idle "Ready"
    ;;

  session-start)
    claude_state_set idle "Session started"
    ;;

  session-end)
    claude_state_stop "Session ended"
    ;;

  *)
    echo "claude-hooks: unknown event '$EVENT'" >&2
    exit 1
    ;;
esac
