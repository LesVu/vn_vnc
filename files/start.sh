#!/bin/bash

binfmts_path="/usr/share/binfmts"

export XDG_RUNTIME_DIR=/run/user/1000
export WLR_LIBINPUT_NO_DEVICES=1
export WLR_BACKENDS=headless

if [ -f "$binfmts_path/box64.conf" ] && [ -f "$binfmts_path/box86.conf" ]; then
	sudo update-binfmts --enable box86.conf
	sudo update-binfmts --enable box64.conf
else
	sudo update-binfmts --enable FEX-x86
	sudo update-binfmts --enable FEX-x86_64
fi

sudo chown root:video /dev/dri/*
sudo mkdir -p $XDG_RUNTIME_DIR
sudo chown "$(id -nu)":"$(id -ng)" $XDG_RUNTIME_DIR

pulseaudio --start --exit-idle-time=-1 &
node ~/novnc_audio/audify.js &

if [ -n "$CAGE" ]; then
	cage -d -- bash -c "wayvnc 0.0.0.0 & lutris" &
else
	wayfire &
fi

~/noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 6080
