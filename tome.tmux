#!/usr/bin/env sh

script_dir=$(dirname "$0")
script_dir=$(
	cd "$script_dir"
	pwd
)

get_option() {
	local res=$(tmux show-option -gqv "$1")
	echo "${res:-$2}"
}

tome_key=$(get_option "@tome_key" p)
tome_scratch_key=$(get_option "@tome_scratch_key" P)

# open tome playbook
tmux bind-key $tome_key run-shell "$script_dir/tome-open-playbook"
# open scratchpad
tmux bind-key $tome_scratch_key run-shell "$script_dir/tome-open-playbook -s"
