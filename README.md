# claude-statusline — Dracula

The [Claude Code](https://claude.com/claude-code) status line I use every day, packaged as-is.

Author: **Emil Dan** — <dan.emil@gmail.com>

```
◈ Opus | [■■■□□□□□□□] 30% (60k/200k) | $1.23 | 5h [■■■■□□□□□□] 42% ↻1h23m | wk [■■■■■■■■□□] 81% ↻2d7h | ↯ high | ❋ Concise | ⌂ my-repo | ⎇ main
```

Shows: model · context used (bar + tokens) · session cost · 5-hour and weekly usage with reset
countdown · effort level · output style · directory · worktree · git branch (yellow when dirty).
Bars go green → yellow → red as they fill. Colors are 24-bit Dracula.

Requires `bash` and `jq`.

## Install

Either run the installer:

```bash
git clone https://github.com/danemil/claude-statusline.git
bash claude-statusline/skills/dracula-statusline/install.sh
```

or install it as a skill and let Claude do it:

```bash
cp -r claude-statusline/skills/dracula-statusline ~/.claude/skills/
# then in Claude Code: /dracula-statusline
```

Restart Claude Code afterwards. Any existing different `~/.claude/scripts/statusline.sh` is
backed up first; other keys in `settings.json` are kept.

## Uninstall

Remove the `statusLine` key from `~/.claude/settings.json` and delete
`~/.claude/scripts/statusline.sh`.

## License

MIT © 2026 Emil Dan <dan.emil@gmail.com>
