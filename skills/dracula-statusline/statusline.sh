#!/bin/bash
# Claude Code status line, Dracula palette (https://draculatheme.com/contribute).
# Copyright (c) 2026 Emil Dan <dan.emil@gmail.com>. MIT License.
#
# Claude Code pipes the session as JSON on stdin; this prints one colored line:
# model | context meter | cost | 5h meter | weekly meter | effort | style | dir | worktree | branch

# Git Bash on Windows often lacks jq on PATH even when it is installed.
PATH="$PATH:$HOME/scoop/shims:${LOCALAPPDATA:-$HOME/AppData/Local}/Microsoft/WinGet/Links"
command -v jq >/dev/null 2>&1 || {
  echo "statusline: jq is required (brew install jq | apt install jq | winget install jqlang.jq)" >&2
  exit 1
}

# fg VAR RRGGBB [attr] -> 24-bit foreground escape stored in VAR
fg() { printf -v "$1" '\033[%s38;2;%d;%d;%dm' "${3:+$3;}" "0x${2:0:2}" "0x${2:2:2}" "0x${2:4:2}"; }
fg PURPLE bd93f9; fg GREEN 50fa7b; fg YELLOW f1fa8c; fg RED ff5555; fg BOLD_RED ff5555 1
fg CYAN 8be9fd;   fg ORANGE ffb86c; fg PINK ff79c6; fg GREY 6272a4; fg FAINT_GREY 6272a4 2
fg TRACK 44475a;  fg GOLD ffd700
R=$'\033[0m' BOLD=$'\033[1m'

eval "$(jq -r '
  def v(p): (p // "") | tostring;
  @sh "model=\(v(.model.display_name))",
  @sh "left=\(v(.context_window.remaining_percentage))",
  @sh "tok=\(v(.context_window.total_input_tokens))",
  @sh "win=\(v(.context_window.context_window_size))",
  @sh "cwd=\(v(.workspace.current_dir))",
  @sh "repo_root=\(v(.worktree.original_repo_dir))",
  @sh "wt_name=\(v(.worktree.name))",
  @sh "branch=\(v(.worktree.branch))",
  @sh "style=\(v(.output_style.name))",
  @sh "cost=\(v(.cost.total_cost_usd))",
  @sh "h5=\(v(.rate_limits.five_hour.used_percentage))",
  @sh "h5_at=\(v(.rate_limits.five_hour.resets_at))",
  @sh "wk=\(v(.rate_limits.seven_day.used_percentage))",
  @sh "wk_at=\(v(.rate_limits.seven_day.resets_at))"
' 2>/dev/null)"

# Effort is not in the session JSON; read it from settings (local wins).
effort=
for f in "$HOME/.claude/settings.local.json" "$HOME/.claude/.claude/settings.local.json" "$HOME/.claude/settings.json"; do
  [ -f "$f" ] && effort=$(jq -r '.effortLevel // empty' "$f" 2>/dev/null) && [ -n "$effort" ] && break
done

# meter COLOR PERCENT -> [■■■□□□□□□□]
meter() {
  local n=$((($2 * 10 + 50) / 100)) i out="$GREY[$R"
  ((n > 10)) && n=10
  for ((i = 0; i < 10; i++)); do
    if ((i < n)); then out+="${1}■$R"; else out+="${TRACK}□$R"; fi
  done
  printf '%s' "$out$GREY]$R"
}
kilo() { awk -v v="$1" 'BEGIN { printf "%.0fk", v / 1000 }'; }

# until_reset EPOCH(s or ms) -> " ↻2d7h" | " ↻1h23m" | " ↻12m" | ""
until_reset() {
  local t=${1%.*} d
  [ -n "$t" ] || return
  ((t > 100000000000)) && t=$((t / 1000))
  d=$((t - $(date +%s)))
  if ((d > 86400)); then printf ' ↻%dd%dh' $((d / 86400)) $((d % 86400 / 3600))
  elif ((d > 3600)); then printf ' ↻%dh%dm' $((d / 3600)) $((d % 3600 / 60))
  elif ((d > 0)); then printf ' ↻%dm' $((d / 60)); fi
}

parts=()

[ -n "$model" ] && parts+=("${PURPLE}◈ $model$R")

if [ -n "$left" ]; then
  used=$((100 - left))
  if ((left < 20)); then c=$RED; elif ((left < 50)); then c=$YELLOW; else c=$GREEN; fi
  seg="$(meter "$c" "$used") $c$used%$R"
  [ -n "$tok" ] && [ -n "$win" ] && seg+="$GREY ($R$c$(kilo "$tok")$R$GREY/$R$c$(kilo "$win")$R$GREY)$R"
  parts+=("$seg")
fi

if [ -n "$cost" ]; then
  dollars=$(awk -v v="$cost" 'BEGIN { if (v + 0 >= 0.005) printf "$%.2f", v + 0 }')
  [ -n "$dollars" ] && parts+=("$GOLD$dollars$R")
fi

# limit LABEL PERCENT RESET_EPOCH
limit() {
  [ -n "$2" ] || return
  local p c
  p=$(awk -v v="$2" 'BEGIN { printf "%.0f", v }')
  if ((p >= 80)); then c=$RED; elif ((p >= 50)); then c=$YELLOW; else c=$GREEN; fi
  parts+=("$c$1$R $(meter "$c" "$p") $c$p%$R$GREY$(until_reset "$3")$R")
}
limit 5h "$h5" "$h5_at"
limit wk "$wk" "$wk_at"

if [ -n "$effort" ]; then
  case $(printf '%s' "$effort" | tr '[:upper:]' '[:lower:]') in
    max | xhigh | high) c=$BOLD_RED ;;
    medium) c=$YELLOW ;;
    low | xlow | minimal) c=$GREEN ;;
    *) c=$FAINT_GREY ;;
  esac
  parts+=("${c}↯ $effort$R")
fi

[ -n "$style" ] && [ "$style" != default ] && parts+=("${PURPLE}❋ $style$R")

dir=${repo_root:-$cwd}
[ -n "$dir" ] && parts+=("${CYAN}⌂ $(basename "$dir")$R")

dirty=
if [ -n "$cwd" ] && git_dir=$(git -C "$cwd" --no-optional-locks rev-parse --git-dir 2>/dev/null); then
  # A worktree Claude Code did not create: name it after its bucket folder.
  if [ -z "$wt_name" ] && [ "$git_dir" != "$(git -C "$cwd" --no-optional-locks rev-parse --git-common-dir 2>/dev/null)" ]; then
    wt_name=$(basename "$(dirname "$cwd")")
    case $wt_name in worktrees | wt | .codex | .claude) wt_name=$(basename "$cwd") ;; esac
  fi
  [ -n "$branch" ] || branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
  if [ -n "$branch" ]; then
    git -C "$cwd" --no-optional-locks diff --quiet 2>/dev/null &&
      git -C "$cwd" --no-optional-locks diff --cached --quiet 2>/dev/null || dirty=1
  fi
fi
[ -n "$wt_name" ] && parts+=("$BOLD${PINK}⊕ worktree:$wt_name$R")
if [ -n "$branch" ]; then
  if [ -n "$dirty" ]; then c=$YELLOW; else c=$ORANGE; fi
  parts+=("${c}⎇ $branch$R")
fi

out=
for i in "${!parts[@]}"; do
  ((i > 0)) && out+="$GREY | $R"
  out+="${parts[$i]}"
done
printf '%s' "$out"
