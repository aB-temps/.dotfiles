#!/bin/bash

#VIDEO="$HOME/.dotfiles/startup/.config/startup/assets/startup_video.mp4"
#cvlc --fullscreen --no-video-title-show --play-and-exit "$VIDEO"
#gsettings set org.gnome.mutter center-new-windows true
setxkbmap -option caps:escape
$HOME/.local/kitty.app/bin/kitty
