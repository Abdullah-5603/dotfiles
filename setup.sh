#!/usr/bin/env bash
set -e

# Paths
SOURCE_DIR="$(pwd)"
NVIM_SRC="$SOURCE_DIR/neovim"
KITTY_SRC="$SOURCE_DIR/kitty"

NVIM_DEST="$HOME/.config/nvim"
KITTY_DEST="$HOME/.config/kitty"
SCRIPTS_SRC="$SOURCE_DIR/scripts"

NGINX_SITE_SRC="$SCRIPTS_SRC/nginx-site.sh"
NGINX_SITE_DEST="/usr/local/bin/nginx-site"

ZSH_SRC="$SCRIPTS_SRC/zshrc"
ZSH_DEST="$HOME/.zshrc"

# Run a command and retry with sudo when necessary
run_cmd() {
  local cmd=$1
  shift

  if "$cmd" "$@"; then
    return 0
  fi

  if command -v sudo >/dev/null 2>&1; then
    echo "Retrying with sudo $cmd $*"
    sudo "$cmd" "$@"
  else
    return 1
  fi
}

# Function to create symlink safely
link_config() {
  local src=$1
  local dest=$2

  if [ ! -e "$src" ] && [ ! -L "$src" ]; then
    echo "Source $src not found, skipping"
    return 1
  fi

  if [ -L "$dest" ]; then
    local current
    current="$(readlink "$dest")"
    if [ "$current" = "$src" ]; then
      echo "Skipping $dest (already linked)"
      return 0
    fi
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    echo "Removing existing $dest"
    run_cmd rm -rf "$dest"
  fi

  echo "Linking $src -> $dest"
  run_cmd ln -s "$src" "$dest"
}

# Create symlinks
link_config "$KITTY_SRC" "$KITTY_DEST"
link_config "$NVIM_SRC" "$NVIM_DEST"
link_config "$NGINX_SITE_SRC" "$NGINX_SITE_DEST"
sudo chmod +x $NGINX_SITE_DEST
link_config "$ZSH_SRC" "$ZSH_DEST"


echo "Symlinks created successfully!"
