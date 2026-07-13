#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Waybar Setup Script
# Applies this dotfiles repo's waybar config (config.jsonc + style.css) on an
# Arch Linux machine running Omarchy, so the bar looks and behaves identically
# to the source machine (workspaces, network speed, clock, tray, etc).
#
# Also installs the Hyprland keybindings for workspaces 11-20 (SUPER+CTRL+
# [1-9,0]), since the waybar config's workspace icons go up to 20 and are
# useless without a way to actually switch to them.
#
# Requires: Arch Linux (pacman) + Omarchy already installed. The config calls
# omarchy-menu / omarchy-launch-* helpers and pulls its colors from
# ~/.config/omarchy/current/theme/waybar.css, so it only works on an Omarchy
# system (https://omarchy.org).
# ─────────────────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WAYBAR_SRC="$DOTFILES_DIR/waybar"
WAYBAR_DEST="$HOME/.config/waybar"
WORKSPACES_SNIPPET="$WAYBAR_SRC/workspaces-11-20.conf"
HYPR_BINDINGS="$HOME/.config/hypr/bindings.conf"
WORKSPACES_MARKER="# Extra workspaces 11-20 with SUPER + CTRL"

check_arch() {
    if ! command_exists pacman; then
        log_error "pacman not found — this script only supports Arch Linux."
        exit 1
    fi
}

check_omarchy() {
    if [[ -d "$HOME/.local/share/omarchy" ]] && command_exists omarchy-menu; then
        log_success "Omarchy detected"
    else
        log_warning "Omarchy not detected. This waybar config relies on omarchy-menu, omarchy-launch-* helpers, and the theme colors at ~/.config/omarchy/current/theme/waybar.css."
        log_warning "Install Omarchy first, then re-run this script."
    fi
}

install_deps() {
    log_info "Installing/verifying required packages (waybar, ttf-jetbrains-mono-nerd, pamixer)..."
    sudo pacman -S --noconfirm --needed waybar ttf-jetbrains-mono-nerd pamixer
    log_success "Dependencies ready"
}

# Symlink a single config file, backing up whatever is already at dest.
link_file() {
    local src=$1
    local dest=$2

    if [[ ! -f "$src" ]]; then
        log_error "Missing source file: $src"
        exit 1
    fi

    if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]; then
        log_success "Already linked: $dest"
        return 0
    fi

    if [[ -e "$dest" ]] || [[ -L "$dest" ]]; then
        local backup="${dest}.backup-$(date +%Y%m%d-%H%M%S)"
        log_info "Backing up existing $dest -> $backup"
        mv "$dest" "$backup"
    fi

    ln -s "$src" "$dest"
    log_success "Linked $(basename "$dest")"
}

# Appends the workspace 11-20 keybindings to ~/.config/hypr/bindings.conf if
# they aren't already there (idempotent — safe to re-run).
install_workspace_bindings() {
    if [[ ! -f "$WORKSPACES_SNIPPET" ]]; then
        log_error "Missing source file: $WORKSPACES_SNIPPET"
        exit 1
    fi

    if [[ ! -f "$HYPR_BINDINGS" ]]; then
        log_warning "$HYPR_BINDINGS not found — skipping workspace 11-20 keybindings"
        return 0
    fi

    if grep -qF "$WORKSPACES_MARKER" "$HYPR_BINDINGS"; then
        log_success "Workspace 11-20 keybindings already present"
        return 0
    fi

    log_info "Adding workspace 11-20 keybindings (SUPER+CTRL+[1-9,0]) to bindings.conf..."
    {
        echo ""
        cat "$WORKSPACES_SNIPPET"
    } >> "$HYPR_BINDINGS"
    log_success "Workspace 11-20 keybindings added"

    if command_exists hyprctl; then
        hyprctl reload >/dev/null 2>&1 || true
        local errors
        errors="$(hyprctl configerrors 2>/dev/null || true)"
        if [[ -n "$errors" && "$errors" != "ok" ]]; then
            log_warning "hyprctl configerrors reported: $errors"
        fi
    fi
}

restart_waybar() {
    log_info "Restarting waybar..."
    if command_exists omarchy-restart-waybar; then
        omarchy-restart-waybar
    else
        killall waybar 2>/dev/null || true
        sleep 0.3
        if command_exists uwsm-app; then
            (uwsm-app -- waybar >/dev/null 2>&1 &)
        else
            (waybar >/dev/null 2>&1 &)
        fi
    fi
    log_success "Waybar restarted"
}

main() {
    check_arch
    check_omarchy
    mkdir -p "$WAYBAR_DEST"
    install_deps
    link_file "$WAYBAR_SRC/config.jsonc" "$WAYBAR_DEST/config.jsonc"
    link_file "$WAYBAR_SRC/style.css" "$WAYBAR_DEST/style.css"
    install_workspace_bindings
    restart_waybar
    log_success "Waybar setup complete — layout, network speed, clock, workspaces 1-20 and all modules now match the source machine"
}

main "$@"
