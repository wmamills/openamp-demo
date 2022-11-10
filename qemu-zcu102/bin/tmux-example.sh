#!/bin/bash

ME=$(readlink -f $0)

do_my-shell() {
	echo "$@"
	/bin/bash -i
	tmux killw
}

do_my-socat() {
	while true; do
		echo "$@"
		sleep 5
	done
}

main() {
if [ -z "$TMUX" ]; then
	tmux start-server
fi

# create a session with five panes
tmux new-session -d -s MySession -n Shell1 -d "$ME subcmd my-shell 1st pane"
tmux split-window -t MySession:0 "$ME subcmd my-shell 2nd pane"
tmux split-window -t MySession:0 "$ME subcmd my-shell 3rd pane"
tmux split-window -t MySession:0 "$ME subcmd my-socat 'hello'"
tmux split-window -t MySession:0 "$ME subcmd my-shell last pane"

# change layout to tiled
tmux select-layout -t MySession:0 tiled

tmux attach -tMySession
}

if [ x"$1" = x"subcmd" ]; then
	CMD=$2
	shift; shift;
	do_$CMD "$@"
else
	main "$@"
fi