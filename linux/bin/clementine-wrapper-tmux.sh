#!/bin/sh

echo tmux new-session -s "Clementine-Wrapper" -d "/opt/niko/bin/clementine-wrapper.sh $*"
tmux new-session -s "Clementine-Wrapper" -d "/opt/niko/bin/clementine-wrapper.sh $*"
