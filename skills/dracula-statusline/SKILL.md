---
name: dracula-statusline
description: Install Emil Dan's Dracula-themed Claude Code status line (model, context bar with tokens, session cost, 5-hour and weekly usage bars with reset timers, effort level, output style, directory, worktree, git branch with dirty state). Use when the user says "/dracula-statusline" or asks to install this status line.
---

# dracula-statusline

Run the installer that ships next to this file, then report its output verbatim:

    bash "<this skill's directory>/install.sh"

It copies `statusline.sh` to `~/.claude/scripts/statusline.sh` (backing up a different
existing file), and sets `statusLine` in `~/.claude/settings.json`, keeping every other key.
Requires `bash` and `jq`. If `jq` is missing, tell the user the install command the
script printed — do not work around it.

Tell the user to restart Claude Code to see the new status line.
