#!/bin/sh
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty' | sed "s|^/Users/kshetty|~|")
model=$(echo "$input" | jq -r '.model.display_name // empty')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# Git branch and status (skip optional locks)
git_info=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" -c core.hooksPath=/dev/null symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" -c core.hooksPath=/dev/null rev-parse --short HEAD 2>/dev/null)
  dirty=$(git -C "$cwd" -c core.hooksPath=/dev/null status --porcelain 2>/dev/null | head -1)
  if [ -n "$dirty" ]; then
    git_info=" $branch*"
  elif [ -n "$branch" ]; then
    git_info=" $branch"
  fi
fi

# Context window indicator
ctx_info=""
if [ -n "$remaining" ]; then
  ctx_info=" ctx:${remaining}%"
fi

# Model short name
model_info=""
if [ -n "$model" ]; then
  model_info=" [$model]"
fi

printf "\033[0;33m%s\033[0m\033[0;32m%s\033[0m\033[0;35m%s\033[0m\033[0;37m%s\033[0m\n" \
  "$cwd" "$git_info" "$model_info" "$ctx_info"
