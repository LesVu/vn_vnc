#!/bin/bash

export WLR_RENDER_DRM_DEVICE=/dev/dri/card0
export XDG_RUNTIME_DIR=/run/user/1000
export WLR_LIBINPUT_NO_DEVICES=1
export WLR_BACKENDS=headless

wayfire &
WAYLAND_DISPLAY=wayland-1 wayvnc 0.0.0.0 &
