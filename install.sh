#!/usr/bin/env bash
# install.sh — Install claude-tmux to ~/.claude-tmux and wire up hooks + tmux config.

set -euo pipefail

INSTALL_DIR="$HOME/.claude-tmux"
SETTINGS_FILE="$HOME/.claude/settings.json"
TMUX_CONF="$HOME/.tmux.conf"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing claude-tmux to $INSTALL_DIR..."

# Copy scripts
mkdir -p "$INSTALL_DIR/bin"
cp "$REPO_DIR/bin/"*.sh "$INSTALL_DIR/bin/"
chmod +x "$INSTALL_DIR/bin/"*.sh

echo "✓ Scripts installed"

# ── tmux config ────────────────────────────────────────────────────────

TMUX_SNIPPET='
# claude-tmux: Claude Code status bar integration
set -g status-interval 2
set -g status-right '"'"'#(~/.claude-tmux/bin/tmux-claude-status.sh #{pane_id})'"'"'
set -g status-right-length 40'

if [[ -f "$TMUX_CONF" ]]; then
  if grep -q "claude-tmux" "$TMUX_CONF"; then
    echo "✓ tmux config already has claude-tmux (skipped)"
  else
    echo "" >> "$TMUX_CONF"
    echo "$TMUX_SNIPPET" >> "$TMUX_CONF"
    echo "✓ Added claude-tmux snippet to $TMUX_CONF"
    echo "  Run: tmux source-file ~/.tmux.conf"
  fi
else
  echo "$TMUX_SNIPPET" > "$TMUX_CONF"
  echo "✓ Created $TMUX_CONF with claude-tmux config"
fi

# ── Claude Code hooks ──────────────────────────────────────────────────

HOOKS_TO_ADD=(
  "PreToolUse:pre-tool"
  "PostToolUse:post-tool"
  "Notification:notification"
  "Stop:stop"
  "SessionStart:session-start"
)

if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo "⚠️  $SETTINGS_FILE not found — create it manually."
  echo "   See examples/claude-settings.jsonc for the hooks config."
else
  if grep -q "claude-tmux" "$SETTINGS_FILE"; then
    echo "✓ Claude Code hooks already reference claude-tmux (skipped)"
    echo "  If paths are wrong, update them in $SETTINGS_FILE"
  else
    echo ""
    echo "⚠️  Automatic patching of settings.json is not supported (it's JSON with comments)."
    echo "   Add these hooks to $SETTINGS_FILE manually:"
    echo "   See: $REPO_DIR/examples/claude-settings.jsonc"
    echo ""
    echo "   Hook commands to add:"
    for entry in "${HOOKS_TO_ADD[@]}"; do
      event="${entry%%:*}"
      arg="${entry##*:}"
      echo "     $event: ~/.claude-tmux/bin/claude-hooks.sh $arg"
    done
  fi
fi

echo ""
echo "Done. Reload tmux config if you haven't:"
echo "  tmux source-file ~/.tmux.conf"
