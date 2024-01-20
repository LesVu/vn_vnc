#!/bin/bash

export WLR_RENDER_DRM_DEVICE=/dev/dri/card0
export XDG_RUNTIME_DIR=/run/user/1000
export WLR_LIBINPUT_NO_DEVICES=1
export WLR_BACKENDS=headless
# export WAYLAND_DISPLAY=wayland-1

sudo update-binfmts --enable box86.conf
sudo update-binfmts --enable box64.conf
sudo chown root:video /dev/dri/renderD128
sudo mkdir -p $XDG_RUNTIME_DIR
sudo chown $(id -nu):$(id -ng) $XDG_RUNTIME_DIR
sudo chown -R $(id -nu):$(id -ng) /Games
wayfire
# wayvnc 0.0.0.0
