#!/usr/bin/env bash

# manage tmux sessions
_tmux-auto () {
  local cc=""
  local sess="auto"
  [ -n "$1" ] && cc="$1"
  [ -n "$2" ] && sess="$2"

  if in_path tmux && [ -z "$TMUX" ]; then
    if tmux has-session -t "$sess" >/dev/null 2>&1; then
      tmux "-2${cc}" attach-session -t "$sess"
    else
      tmux "-2${cc}" new-session -s "$sess"
    fi
  fi
}
tmux-auto () {
  _tmux-auto "" "$1"
}
tmux-cc () {
  _tmux-auto "CC" "$1"
}
