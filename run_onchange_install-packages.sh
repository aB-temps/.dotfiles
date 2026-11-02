#! /bin/sh

sudo dnf copr enable -y scottames/ghostty
sudo dnf install -y \
	niri \
	xwayland-satellite \
	fuzzel \
	mako \
	waybar \
	swaylock \
	swayidle \
	swaybg \
	ghostty \
	kanshi \
	zsh \
	zsh-autosuggestions \
	zsh-syntax-highlighting \
	neovim \
	git \
	gcc \
	make \
	unzip \
	ripgrep \
	fd-find \
	fzf \
	brightnessctl \
	pavucontrol
