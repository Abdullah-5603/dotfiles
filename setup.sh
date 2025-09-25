#!/usr/bin/env bash
set -e

# Paths
SOURCE_DIR="$(pwd)"
NVIM_SRC="$SOURCE_DIR/neovim"
KITTY_SRC="$SOURCE_DIR/kitty"

NVIM_DEST="$HOME/.config/nvim"
KITTY_DEST="$HOME/.config/kitty"

# Function to create symlink safely
link_config() {
  local src=$1
  local dest=$2

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    echo "Removing existing $dest"
    rm -rf "$dest"
  fi

  echo "Linking $src -> $dest"
  ln -s "$src" "$dest"
}

# Create symlinks
link_config "$KITTY_SRC" "$KITTY_DEST"
link_config "$NVIM_SRC" "$NVIM_DEST"

echo "Symlinks created successfully!"
