#!/bin/sh

cd $(dirname $0)

echo tmux new-session -s "Clementine-Wrapper" -d "./clementine-wrapper.sh $*"
tmux new-session -s "Clementine-Wrapper" -d "./clementine-wrapper.sh $*"
