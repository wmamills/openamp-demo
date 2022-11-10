#!/bin/bash

ME=$(readlink -f $0)

tmux-panel-title() {
    printf '\033]2;%s\033\\' "$1"
}


do_my-shell() {
	tmux-panel-title "shell $@"
	echo "$@"
	/bin/bash -i
	tmux killw
}

do_my-socat() {
	tmux-panel-title "socat $@"
	while true; do
		echo "$@"
		sleep 5
	done
}

main() {
if [ -z "$TMUX" ]; then
	tmux start-server
	tmux new-session -d -s QEMU -n qemu-zcu102 -d "$ME subcmd my-shell 1st pane"
	SESS="QEMU"
	tmux set -s -t $SESS mouse on
else
	SESS=""
	tmux new-window -d -n qemu-zcu102 -d "$ME subcmd my-shell 1st pane"
	tmux set -s mouse on
fi

tmux set -w -t $SESS:qemu-zcu102 pane-border-status top

# create a session with four panes
tmux split-window -h -t $SESS:qemu-zcu102 "$ME subcmd my-shell 2nd pane"
tmux split-window -v -t $SESS:qemu-zcu102 "$ME subcmd my-socat 'hello'"
tmux split-window -v -t $SESS:qemu-zcu102 "$ME subcmd my-socat 'goodbye'"

tmux select-pane -t $SESS:qemu-zcu102.0

if [ -n "$SESS" ]; then
	tmux attach -t$SESS:qemu-zcu102
else
	tmux select-window -t:qemu-zcu102
fi
}

if [ x"$1" = x"subcmd" ]; then
	CMD=$2
	shift; shift;
	do_$CMD "$@"
else
	main "$@"
fi