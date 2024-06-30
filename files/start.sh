#!/bin/bash

export WLR_RENDER_DRM_DEVICE=/dev/dri/card1
export XDG_RUNTIME_DIR=/run/user/1000
export WLR_LIBINPUT_NO_DEVICES=1
export WLR_BACKENDS=headless

sudo update-binfmts --enable box86.conf
sudo update-binfmts --enable box64.conf
sudo chown root:video /dev/dri/card*
sudo chown root:render /dev/dri/render*
sudo mkdir -p $XDG_RUNTIME_DIR
sudo chown $(id -nu):$(id -ng) $XDG_RUNTIME_DIR
sudo chown -R $(id -nu):$(id -ng) /Games

pulseaudio --start --exit-idle-time=-1 &
node ~/novnc_audio/audify.js &
# sudo service dbus restart
# sudo /usr/bin/rustdesk --service &
# sudo /usr/lib/polkit-1/polkitd &
wayfire &
~/noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 6080
