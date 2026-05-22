#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KITTY_SRC="$DOTFILES_DIR/kitty"
ZSH_SRC="$DOTFILES_DIR/scripts/zshrc"

KITTY_DEST="$HOME/.config/kitty"
ZSH_DEST="$HOME/.zshrc"
BACKUP_SUFFIX="$(date +%Y%m%d-%H%M%S)"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
step() {
  echo ""
  echo -e "${CYAN}============================================================${NC}"
  echo -e "${CYAN}$1${NC}"
  echo -e "${CYAN}============================================================${NC}"
}

require_mint() {
  if [[ ! -f /etc/os-release ]]; then
    log_error "/etc/os-release not found. Cannot verify Linux Mint."
    exit 1
  fi

  # shellcheck source=/dev/null
  source /etc/os-release
  if [[ "${ID:-}" != "linuxmint" ]]; then
    log_error "This script is for Linux Mint only. Detected ID=${ID:-unknown}."
    exit 1
  fi
  log_ok "Linux Mint detected (${PRETTY_NAME:-unknown})"
}

require_sources() {
  [[ -d "$KITTY_SRC" ]] || { log_error "Missing $KITTY_SRC"; exit 1; }
  [[ -f "$ZSH_SRC" ]] || { log_error "Missing $ZSH_SRC"; exit 1; }
}

pkg_installed() {
  dpkg -s "$1" >/dev/null 2>&1
}

install_packages() {
  step "Installing required packages"
  sudo apt-get update

  local required=(
    zsh
    kitty
    git
    curl
    wget
    unzip
    fontconfig
  )

  local optional=(
    bat
    fd-find
    fzf
    ripgrep
    eza
  )

  for pkg in "${required[@]}"; do
    if pkg_installed "$pkg"; then
      log_ok "$pkg already installed"
    else
      log_info "Installing $pkg"
      sudo apt-get install -y "$pkg"
    fi
  done

  for pkg in "${optional[@]}"; do
    if pkg_installed "$pkg"; then
      log_ok "$pkg already installed (optional)"
    else
      log_info "Trying optional package $pkg"
      if sudo apt-get install -y "$pkg"; then
        log_ok "Installed optional package $pkg"
      else
        log_warn "Could not install optional package $pkg"
      fi
    fi
  done

  if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    log_ok "Linked batcat -> ~/.local/bin/bat"
  fi

  if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    log_ok "Linked fdfind -> ~/.local/bin/fd"
  fi
}

install_oh_my_zsh() {
  step "Installing Oh-My-Zsh + plugins"

  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log_info "Installing Oh-My-Zsh"
    RUNZSH=no CHSH=no sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    log_ok "Oh-My-Zsh installed"
  else
    log_ok "Oh-My-Zsh already installed"
  fi

  local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  if [[ ! -d "$zsh_custom/plugins/zsh-autosuggestions" ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions \
      "$zsh_custom/plugins/zsh-autosuggestions"
  fi
  if [[ ! -d "$zsh_custom/plugins/zsh-syntax-highlighting" ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting \
      "$zsh_custom/plugins/zsh-syntax-highlighting"
  fi
  if [[ ! -d "$zsh_custom/plugins/zsh-history-substring-search" ]]; then
    git clone https://github.com/zsh-users/zsh-history-substring-search \
      "$zsh_custom/plugins/zsh-history-substring-search"
  fi
  log_ok "Zsh plugins are ready"
}

install_firacode_nerd_font() {
  step "Installing FiraCode Nerd Font"

  if fc-list 2>/dev/null | grep -qi "FiraCode.*Nerd"; then
    log_ok "FiraCode Nerd Font already installed"
    return
  fi

  local font_dir="$HOME/.local/share/fonts"
  local tmp_dir
  tmp_dir="$(mktemp -d)"

  mkdir -p "$font_dir"
  log_info "Downloading latest FiraCode Nerd Font zip"
  curl -fL \
    -o "$tmp_dir/FiraCode.zip" \
    "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"
  unzip -oq "$tmp_dir/FiraCode.zip" -d "$font_dir"
  fc-cache -fv "$font_dir" >/dev/null 2>&1 || true
  rm -rf "$tmp_dir"

  log_ok "FiraCode Nerd Font installed"
}

backup_if_exists() {
  local target="$1"
  if [[ -e "$target" || -L "$target" ]]; then
    local backup="${target}.backup-${BACKUP_SUFFIX}"
    mv "$target" "$backup"
    log_warn "Backed up $target -> $backup"
  fi
}

configure_kitty() {
  step "Configuring kitty"

  mkdir -p "$HOME/.config"
  backup_if_exists "$KITTY_DEST"
  ln -s "$KITTY_SRC" "$KITTY_DEST"
  log_ok "Linked $KITTY_DEST -> $KITTY_SRC"

  # The config includes ~/.config/omarchy/current/theme/kitty.conf.
  # Create a minimal fallback so kitty starts cleanly on non-Omarchy systems.
  local omarchy_theme="$HOME/.config/omarchy/current/theme/kitty.conf"
  if [[ ! -f "$omarchy_theme" ]]; then
    mkdir -p "$(dirname "$omarchy_theme")"
    cat > "$omarchy_theme" <<'EOF'
foreground #e5e9f0
background #0f111a
selection_foreground #0f111a
selection_background #88c0d0
cursor #d8dee9
color0 #3b4252
color1 #bf616a
color2 #a3be8c
color3 #ebcb8b
color4 #81a1c1
color5 #b48ead
color6 #88c0d0
color7 #e5e9f0
color8 #4c566a
color9 #bf616a
color10 #a3be8c
color11 #ebcb8b
color12 #81a1c1
color13 #b48ead
color14 #8fbcbb
color15 #eceff4
EOF
    log_ok "Created fallback Omarchy kitty theme: $omarchy_theme"
  else
    log_ok "Omarchy kitty theme already exists"
  fi
}

configure_zshrc() {
  step "Configuring ~/.zshrc"

  backup_if_exists "$ZSH_DEST"

  # Keep current zsh config, but replace hardcoded /home/nprime with the current HOME.
  sed "s|/home/nprime|$HOME|g" "$ZSH_SRC" > "$ZSH_DEST"
  log_ok "Installed $ZSH_DEST from $ZSH_SRC"
}

set_default_shell() {
  step "Setting zsh as default shell"

  local zsh_path
  zsh_path="$(command -v zsh)"
  if [[ -z "$zsh_path" ]]; then
    log_error "zsh not found after install"
    exit 1
  fi

  if ! grep -q "$zsh_path" /etc/shells; then
    echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  fi

  if [[ "${SHELL:-}" != "$zsh_path" ]]; then
    chsh -s "$zsh_path"
    log_ok "Default shell changed to $zsh_path (effective on next login)"
  else
    log_ok "zsh is already the default shell"
  fi
}

print_summary() {
  echo ""
  echo -e "${GREEN}Done.${NC}"
  echo "Applied on Linux Mint:"
  echo "1. zsh + Oh-My-Zsh + plugins"
  echo "2. kitty + current kitty config symlink"
  echo "3. current zshrc content copied with HOME-path substitution"
  echo "4. FiraCode Nerd Font"
  echo ""
  echo "Open a new terminal or run: exec zsh"
}

main() {
  step "Mint Kitty Setup"
  require_mint
  require_sources
  install_packages
  install_oh_my_zsh
  install_firacode_nerd_font
  configure_kitty
  configure_zshrc
  set_default_shell
  print_summary
}

main "$@"
