#!/bin/bash

binfmts_path="/usr/share/binfmts"

export XDG_RUNTIME_DIR=/run/user/1000 WLR_LIBINPUT_NO_DEVICES=1 WLR_BACKENDS=headless

if [ -f "$binfmts_path/box64.conf" ] && [ -f "$binfmts_path/box86.conf" ]; then
  sudo update-binfmts --enable box86.conf
  sudo update-binfmts --enable box64.conf
elif [ -f "$binfmts_path/FEX-x86.conf" ] && [ -f "$binfmts_path/FEX-x86_64.conf" ]; then
  sudo update-binfmts --enable FEX-x86
  sudo update-binfmts --enable FEX-x86_64
fi

sudo chown root:video /dev/dri/*
sudo mkdir -p $XDG_RUNTIME_DIR
sudo chown "$(id -nu)":"$(id -ng)" $XDG_RUNTIME_DIR

pulseaudio --start --exit-idle-time=-1 &

if [ -x /usr/local/bin/audio_feed ]; then
  /usr/local/bin/audio_feed 0.0.0.0:5700 &
else
  node ~/novnc_audio/audify.js &
fi

labwc &

~/noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 6100
