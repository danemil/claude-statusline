#!/bin/bash
# Installs the Dracula status line into ~/.claude and points settings.json at it.
set -euo pipefail
command -v jq >/dev/null || { echo "jq is required: brew install jq | apt install jq | winget install jqlang.jq" >&2; exit 1; }

src="$(cd "$(dirname "$0")" && pwd)/statusline.sh"
dst="$HOME/.claude/scripts/statusline.sh"
settings="$HOME/.claude/settings.json"

mkdir -p "$(dirname "$dst")"
if [ -f "$dst" ] && ! cmp -s "$src" "$dst"; then
  cp -p "$dst" "$dst.bak-$(date +%Y%m%d%H%M%S)"
  echo "Backed up existing $dst"
fi
cp "$src" "$dst" && chmod +x "$dst"

[ -s "$settings" ] || echo '{}' > "$settings"
tmp=$(mktemp)
jq '.statusLine = {"type":"command","command":"~/.claude/scripts/statusline.sh"}' "$settings" > "$tmp" && mv "$tmp" "$settings"

echo "Installed $dst and set statusLine in $settings. Restart Claude Code to see it."
