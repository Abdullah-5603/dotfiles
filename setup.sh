#!/usr/bin/env bash
set -e

# ─────────────────────────────────────────────────────────────────────────────
# Dotfiles Setup Script
# Auto-detects the Linux distribution (or macOS) and installs everything needed.
#
# Supported package managers: pacman, apt, dnf/yum, zypper, apk, brew
# Distro families are resolved from /etc/os-release (ID + ID_LIKE), with a
# fallback that probes for an available package manager.
# ─────────────────────────────────────────────────────────────────────────────

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Paths
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_SRC="$DOTFILES_DIR/neovim"
KITTY_SRC="$DOTFILES_DIR/kitty"
SCRIPTS_SRC="$DOTFILES_DIR/scripts"
ZSH_SRC="$SCRIPTS_SRC/zshrc"

NVIM_DEST="$HOME/.config/nvim"
KITTY_DEST="$HOME/.config/kitty"
ZSH_DEST="$HOME/.zshrc"
NGINX_SITE_SRC="$SCRIPTS_SRC/nginx-site.sh"
NGINX_SITE_DEST="/usr/local/bin/nginx-site"
CLEANUP_SRC="$SCRIPTS_SRC/cleanup.sh"
CLEANUP_DEST="/usr/local/bin/cleanup"

# Populated by detect_os
OS=""          # raw distro id (arch, ubuntu, fedora, macos, ...)
OS_FAMILY=""   # normalized family (arch, debian, rhel, suse, alpine, macos)
PKG=""         # package manager (pacman, apt, dnf, yum, zypper, apk, brew)

# ─────────────────────────────────────────────────────────────────────────────
# Helper Functions
# ─────────────────────────────────────────────────────────────────────────────

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

log_step() {
    echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Run a command, retrying with sudo when it fails and sudo is available.
run_cmd() {
    local cmd=$1
    shift

    if "$cmd" "$@" 2>/dev/null; then
        return 0
    fi

    if command_exists sudo; then
        sudo "$cmd" "$@"
    else
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# OS / Distro Detection
# ─────────────────────────────────────────────────────────────────────────────

# Map a package manager to a normalized family name.
pkg_to_family() {
    case "$1" in
        pacman) echo "arch" ;;
        apt) echo "debian" ;;
        dnf|yum) echo "rhel" ;;
        zypper) echo "suse" ;;
        apk) echo "alpine" ;;
        brew) echo "macos" ;;
        *) echo "unknown" ;;
    esac
}

# Last-resort detection: probe for whichever package manager is installed.
detect_pkg_by_probe() {
    for pm in pacman apt-get dnf yum zypper apk brew; do
        if command_exists "$pm"; then
            case "$pm" in
                apt-get) echo "apt" ;;
                *) echo "$pm" ;;
            esac
            return 0
        fi
    done
    echo "unknown"
}

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"; OS_FAMILY="macos"; PKG="brew"
        log_info "Detected OS: macOS (Package Manager: brew)"
        return
    fi

    # Prefer the freedesktop standard /etc/os-release.
    if [[ -r /etc/os-release ]]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        OS="${ID:-unknown}"
        local likes=" ${ID:-} ${ID_LIKE:-} "

        if   [[ "$likes" == *" arch "* || "$likes" == *" archlinux "* ]]; then
            OS_FAMILY="arch";   PKG="pacman"
        elif [[ "$likes" == *" debian "* || "$likes" == *" ubuntu "* ]]; then
            OS_FAMILY="debian"; PKG="apt"
        elif [[ "$likes" == *" fedora "* || "$likes" == *" rhel "* || "$likes" == *" centos "* ]]; then
            OS_FAMILY="rhel";   PKG="$(command_exists dnf && echo dnf || echo yum)"
        elif [[ "$likes" == *" suse "* || "$likes" == *" opensuse "* ]]; then
            OS_FAMILY="suse";   PKG="zypper"
        elif [[ "$likes" == *" alpine "* ]]; then
            OS_FAMILY="alpine"; PKG="apk"
        else
            # Unknown ID/ID_LIKE — fall back to probing the package manager.
            PKG="$(detect_pkg_by_probe)"
            OS_FAMILY="$(pkg_to_family "$PKG")"
        fi
    else
        # No os-release (very minimal systems) — probe.
        OS="unknown"
        PKG="$(detect_pkg_by_probe)"
        OS_FAMILY="$(pkg_to_family "$PKG")"
    fi

    log_info "Detected OS: $OS (family: $OS_FAMILY, package manager: $PKG)"
}

# ─────────────────────────────────────────────────────────────────────────────
# Package Manager Abstraction
# ─────────────────────────────────────────────────────────────────────────────

pkg_update() {
    log_step "Updating Package Metadata"
    case "$PKG" in
        pacman) sudo pacman -Sy ;;
        apt)    sudo apt-get update ;;
        dnf)    sudo dnf check-update || true ;;
        yum)    sudo yum check-update || true ;;
        zypper) sudo zypper refresh ;;
        apk)    sudo apk update ;;
        brew)   brew update ;;
        *)      log_warning "Unknown package manager; skipping metadata update" ;;
    esac
    log_success "Package metadata updated"
}

# Install one or more literal package names for the current package manager.
# Returns non-zero on failure (caller decides whether that is fatal).
pkg_install_raw() {
    case "$PKG" in
        pacman) sudo pacman -S --noconfirm --needed "$@" ;;
        apt)    sudo apt-get install -y "$@" ;;
        dnf)    sudo dnf install -y "$@" ;;
        yum)    sudo yum install -y "$@" ;;
        zypper) sudo zypper install -y "$@" ;;
        apk)    sudo apk add "$@" ;;
        brew)   brew install "$@" ;;
        *)      return 1 ;;
    esac
}

# Install a logical tool, choosing the right package name per package manager.
# Usage: install_tool <friendly> <check_cmd> <arch> <apt> <dnf> <zypper> <apk> <brew>
# Pass an empty string for package managers where the tool is unavailable.
# Honors the "best-effort + warn" strategy: a missing package is a warning, not
# a fatal error.
install_tool() {
    local friendly="$1" check="$2" arch="$3" apt="$4" dnf="$5" zypper="$6" apk="$7" brew="$8"

    if [[ -n "$check" ]] && command_exists "$check"; then
        log_success "$friendly already installed"
        return 0
    fi

    local pkg=""
    case "$PKG" in
        pacman) pkg="$arch" ;;
        apt)    pkg="$apt" ;;
        dnf|yum) pkg="$dnf" ;;
        zypper) pkg="$zypper" ;;
        apk)    pkg="$apk" ;;
        brew)   pkg="$brew" ;;
    esac

    if [[ -z "$pkg" ]]; then
        log_warning "$friendly is not available for $PKG — skipping"
        return 1
    fi

    log_info "Installing $friendly ($pkg)..."
    if pkg_install_raw "$pkg"; then
        log_success "$friendly installed"
        return 0
    else
        log_warning "Could not install $friendly via $PKG — skipping"
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Core Dependencies
# ─────────────────────────────────────────────────────────────────────────────

install_core_deps() {
    log_step "Installing Core Dependencies"

    # Install the essentials explicitly so package names are correct per distro.
    # Each call is best-effort: a missing package warns and continues.
    install_tool "git"        git        git           git                git        git        git        git        || true
    install_tool "curl"       curl       curl          curl               curl       curl       curl       curl       || true
    install_tool "wget"       wget       wget          wget               wget       wget       wget       wget       || true
    install_tool "unzip"      unzip      unzip         unzip              unzip      unzip      unzip      unzip      || true
    install_tool "tar"        tar        tar           tar                tar        tar        tar        ""         || true
    install_tool "fontconfig" fc-cache   fontconfig    fontconfig         fontconfig fontconfig fontconfig ""         || true

    # Compiler toolchain (used by some Neovim plugins / treesitter).
    case "$OS_FAMILY" in
        arch)   install_tool "base-devel" gcc base-devel "" "" "" "" "" || true ;;
        debian) install_tool "build-essential" gcc "" build-essential "" "" "" "" || true ;;
        rhel)   pkg_install_raw gcc gcc-c++ make >/dev/null 2>&1 || log_warning "Could not install build tools" ;;
        suse)   pkg_install_raw gcc gcc-c++ make >/dev/null 2>&1 || log_warning "Could not install build tools" ;;
        alpine) pkg_install_raw build-base >/dev/null 2>&1 || log_warning "Could not install build-base" ;;
        macos)  : ;; # Xcode CLT provides the toolchain
    esac
}

# ─────────────────────────────────────────────────────────────────────────────
# Zsh + Oh-My-Zsh + Plugins
# ─────────────────────────────────────────────────────────────────────────────

install_zsh() {
    log_step "Installing Zsh"
    install_tool "zsh" zsh zsh zsh zsh zsh zsh zsh || true
}

install_oh_my_zsh() {
    log_step "Installing Oh-My-Zsh"

    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_success "Oh-My-Zsh already installed"
        return
    fi

    log_info "Installing Oh-My-Zsh..."
    RUNZSH=no CHSH=no sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    log_success "Oh-My-Zsh installed"
}

install_zsh_plugins() {
    log_step "Installing Zsh Plugins"

    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    local plugin name url
    local plugins=(
        "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions"
        "zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting"
        "zsh-history-substring-search|https://github.com/zsh-users/zsh-history-substring-search"
    )

    for plugin in "${plugins[@]}"; do
        name="${plugin%%|*}"
        url="${plugin#*|}"
        if [[ -d "$ZSH_CUSTOM/plugins/$name" ]]; then
            log_success "$name already installed"
        else
            log_info "Installing $name..."
            git clone --depth=1 "$url" "$ZSH_CUSTOM/plugins/$name"
            log_success "$name installed"
        fi
    done
}

# ─────────────────────────────────────────────────────────────────────────────
# Neovim
# ─────────────────────────────────────────────────────────────────────────────

install_neovim() {
    log_step "Installing Neovim"
    install_tool "neovim" nvim neovim neovim neovim neovim neovim neovim || true
}

# ─────────────────────────────────────────────────────────────────────────────
# Kitty Terminal
# ─────────────────────────────────────────────────────────────────────────────

install_kitty() {
    log_step "Installing Kitty Terminal"

    if command_exists kitty; then
        log_success "Kitty already installed"
        return
    fi

    if [[ "$PKG" == "brew" ]]; then
        log_info "Installing Kitty (cask)..."
        brew install --cask kitty && log_success "Kitty installed" \
            || log_warning "Could not install Kitty"
        return
    fi

    install_tool "kitty" kitty kitty kitty kitty kitty kitty kitty || true
}

# ─────────────────────────────────────────────────────────────────────────────
# Modern CLI Tools
# ─────────────────────────────────────────────────────────────────────────────

install_cli_tools() {
    log_step "Installing Modern CLI Tools"

    # eza (modern ls). Falls back to exa where eza is unavailable.
    if command_exists eza || command_exists exa; then
        log_success "eza/exa already installed"
    else
        install_tool "eza" eza eza eza eza eza eza eza \
            || install_tool "exa" exa exa exa exa exa exa exa
    fi

    # bat (modern cat). On Debian/Ubuntu the binary is "batcat".
    if command_exists bat || command_exists batcat; then
        log_success "bat already installed"
    else
        install_tool "bat" bat bat bat bat bat bat bat || true
    fi

    # fd (modern find). On Debian/Ubuntu the package is "fd-find" / binary "fdfind".
    if command_exists fd || command_exists fdfind; then
        log_success "fd already installed"
    else
        install_tool "fd" fd fd fd-find fd-find fd fd fd || true
    fi

    # fzf (fuzzy finder)
    install_tool "fzf" fzf fzf fzf fzf fzf fzf fzf || true

    # ripgrep (modern grep)
    install_tool "ripgrep" rg ripgrep ripgrep ripgrep ripgrep ripgrep ripgrep || true

    # Create convenience symlinks for Debian's renamed binaries.
    if command_exists batcat && ! command_exists bat; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
        log_success "Linked batcat -> ~/.local/bin/bat"
    fi
    if command_exists fdfind && ! command_exists fd; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
        log_success "Linked fdfind -> ~/.local/bin/fd"
    fi

    log_success "CLI tools installation complete"
}

# ─────────────────────────────────────────────────────────────────────────────
# Nerd Fonts (FiraCode)
# ─────────────────────────────────────────────────────────────────────────────

install_nerd_fonts() {
    log_step "Installing Nerd Fonts (FiraCode)"

    local FONT_DIR
    if [[ "$OS_FAMILY" == "macos" ]]; then
        FONT_DIR="$HOME/Library/Fonts"
    else
        FONT_DIR="$HOME/.local/share/fonts"
    fi

    if fc-list 2>/dev/null | grep -qi "FiraCode.*Nerd" || [[ -f "$FONT_DIR/FiraCodeNerdFont-Regular.ttf" ]]; then
        log_success "FiraCode Nerd Font already installed"
        return 0
    fi

    # Native package where available (Arch).
    if [[ "$PKG" == "pacman" ]]; then
        if sudo pacman -S --noconfirm --needed ttf-firacode-nerd 2>/dev/null; then
            log_success "FiraCode Nerd Font installed via pacman"
            return 0
        fi
    fi

    # Otherwise download from the Nerd Fonts release.
    log_info "Downloading FiraCode Nerd Font..."
    mkdir -p "$FONT_DIR"

    local TEMP_DIR
    TEMP_DIR=$(mktemp -d)
    if curl -fLo "$TEMP_DIR/FiraCode.zip" \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"; then
        unzip -oq "$TEMP_DIR/FiraCode.zip" -d "$FONT_DIR"
        command_exists fc-cache && fc-cache -f "$FONT_DIR" >/dev/null 2>&1
        log_success "FiraCode Nerd Font installed"
    else
        log_warning "Could not download FiraCode Nerd Font — skipping"
    fi
    rm -rf "$TEMP_DIR"
}

# ─────────────────────────────────────────────────────────────────────────────
# NVM (Node Version Manager)
# ─────────────────────────────────────────────────────────────────────────────

install_nvm() {
    log_step "Installing NVM (Node Version Manager)"

    export NVM_DIR="$HOME/.config/nvm"

    if [[ -d "$NVM_DIR" ]] && [[ -s "$NVM_DIR/nvm.sh" ]]; then
        log_success "NVM already installed"
        return
    fi

    log_info "Installing NVM..."
    mkdir -p "$NVM_DIR"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    log_success "NVM installed"
}

# ─────────────────────────────────────────────────────────────────────────────
# Symlinks
# ─────────────────────────────────────────────────────────────────────────────

link_config() {
    local src=$1
    local dest=$2

    if [[ ! -e "$src" ]] && [[ ! -L "$src" ]]; then
        log_warning "Source $src not found, skipping"
        return 1
    fi

    if [[ -L "$dest" ]]; then
        local current
        current="$(readlink "$dest")"
        if [[ "$current" == "$src" ]]; then
            log_success "Already linked: $dest"
            return 0
        fi
    fi

    local parent_dir
    parent_dir="$(dirname "$dest")"
    [[ -d "$parent_dir" ]] || mkdir -p "$parent_dir"

    if [[ -e "$dest" ]] || [[ -L "$dest" ]]; then
        local backup="${dest}.backup-$(date +%Y%m%d-%H%M%S)"
        log_info "Backing up existing $dest -> $backup"
        run_cmd mv "$dest" "$backup"
    fi

    log_info "Linking $src -> $dest"
    run_cmd ln -s "$src" "$dest"
    log_success "Linked: $(basename "$dest")"
}

# The zshrc is generalized (uses $HOME), so a plain symlink is safe for any user.
create_symlinks() {
    log_step "Creating Symlinks"

    link_config "$NVIM_SRC" "$NVIM_DEST"
    link_config "$KITTY_SRC" "$KITTY_DEST"
    link_config "$ZSH_SRC" "$ZSH_DEST"

    if [[ -f "$NGINX_SITE_SRC" ]]; then
        link_config "$NGINX_SITE_SRC" "$NGINX_SITE_DEST"
        run_cmd chmod +x "$NGINX_SITE_DEST" 2>/dev/null || true
    fi

    if [[ -f "$CLEANUP_SRC" ]]; then
        link_config "$CLEANUP_SRC" "$CLEANUP_DEST"
        run_cmd chmod +x "$CLEANUP_DEST" 2>/dev/null || true
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Default Shell
# ─────────────────────────────────────────────────────────────────────────────

set_default_shell() {
    log_step "Setting Zsh as Default Shell"

    if ! command_exists zsh; then
        log_warning "Zsh is not installed — skipping default shell change"
        return
    fi

    if [[ "$(basename "${SHELL:-}")" == "zsh" ]]; then
        log_success "Zsh is already the default shell"
        return
    fi

    local zsh_path
    zsh_path="$(command -v zsh)"

    if [[ -w /etc/shells ]] || command_exists sudo; then
        if ! grep -q "^$zsh_path$" /etc/shells 2>/dev/null; then
            echo "$zsh_path" | run_cmd tee -a /etc/shells >/dev/null
        fi
    fi

    if chsh -s "$zsh_path" 2>/dev/null; then
        log_success "Default shell changed to Zsh (takes effect on next login)"
    else
        log_warning "Could not change default shell automatically. Run: chsh -s $zsh_path"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Post-Install Message
# ─────────────────────────────────────────────────────────────────────────────

print_success_message() {
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}         Dotfiles Installation Complete!${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${CYAN}What was installed:${NC}"
    echo -e "    - Zsh + Oh-My-Zsh with plugins"
    echo -e "    - Neovim with lazy.nvim plugin manager"
    echo -e "    - Kitty terminal emulator"
    echo -e "    - Modern CLI tools (eza, bat, fd, fzf, ripgrep)"
    echo -e "    - FiraCode Nerd Font"
    echo -e "    - NVM (Node Version Manager)"
    echo ""
    echo -e "  ${CYAN}Configuration symlinks created:${NC}"
    echo -e "    - ~/.config/nvim    -> Neovim config"
    echo -e "    - ~/.config/kitty   -> Kitty config"
    echo -e "    - ~/.zshrc          -> Zsh config"
    echo ""
    echo -e "  ${YELLOW}Next steps:${NC}"
    echo -e "    1. Log out and log back in (or run: ${CYAN}exec zsh${NC})"
    echo -e "    2. Open Neovim to let plugins auto-install"
    echo -e "    3. Enjoy your new dev environment!"
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
}

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────

main() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              Dotfiles Setup Script                           ║${NC}"
    echo -e "${CYAN}║         Automated Environment Configuration                  ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    detect_os

    if [[ "$PKG" == "unknown" || -z "$PKG" ]]; then
        log_error "Could not detect a supported package manager."
        log_error "Supported: pacman, apt, dnf/yum, zypper, apk, brew."
        log_error "Please install dependencies manually, then re-run for symlinks."
        exit 1
    fi

    # On macOS, make sure Homebrew exists first.
    if [[ "$PKG" == "brew" ]] && ! command_exists brew; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    pkg_update
    install_core_deps
    install_zsh
    install_oh_my_zsh
    install_zsh_plugins
    install_neovim
    install_kitty
    install_cli_tools
    install_nerd_fonts
    install_nvm
    create_symlinks
    set_default_shell

    print_success_message
}

main "$@"
