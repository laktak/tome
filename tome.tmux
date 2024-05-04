#!/usr/bin/env bash

get_option() {
    local res=$(tmux show-option -gqv "$1")
    echo "${res:-$2}"
}

tome_key=$(get_option "@tome_key" p)
tome_height=$(get_option "@tome_height" 8)
tome_playbook=$(get_option "@tome_playbook" .playbook.sh)

# open tome playbook
tmux bind-key $tome_key run-shell 'tmux split-window -c "#{pane_current_path}" -vb -l '$tome_height' "vim -c TomePlayBook '$tome_playbook'"'
