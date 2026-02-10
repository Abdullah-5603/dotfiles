#!/usr/bin/env bash
set -e

# ─────────────────────────────────────────────────────────────────────────────
# Dotfiles Setup Script
# Automatically detects OS and installs all necessary dependencies
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

# ─────────────────────────────────────────────────────────────────────────────
# Helper Functions
# ─────────────────────────────────────────────────────────────────────────────

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Run a command and retry with sudo when necessary
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
# OS Detection
# ─────────────────────────────────────────────────────────────────────────────

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        PACKAGE_MANAGER="brew"
    elif [[ -f /etc/arch-release ]]; then
        OS="arch"
        PACKAGE_MANAGER="pacman"
    elif [[ -f /etc/debian_version ]]; then
        OS="debian"
        PACKAGE_MANAGER="apt"
    elif [[ -f /etc/fedora-release ]]; then
        OS="fedora"
        PACKAGE_MANAGER="dnf"
    elif [[ -f /etc/redhat-release ]]; then
        OS="rhel"
        PACKAGE_MANAGER="dnf"
    elif [[ -f /etc/opensuse-release ]] || [[ -f /etc/SUSE-brand ]]; then
        OS="opensuse"
        PACKAGE_MANAGER="zypper"
    else
        OS="unknown"
        PACKAGE_MANAGER="unknown"
    fi

    log_info "Detected OS: $OS (Package Manager: $PACKAGE_MANAGER)"
}

# ─────────────────────────────────────────────────────────────────────────────
# Package Installation Functions
# ─────────────────────────────────────────────────────────────────────────────

install_package() {
    local package=$1
    local package_alt=${2:-$1}  # Alternative name for different package managers

    case $PACKAGE_MANAGER in
        pacman)
            sudo pacman -S --noconfirm --needed "$package"
            ;;
        apt)
            sudo apt-get install -y "$package_alt"
            ;;
        dnf)
            sudo dnf install -y "$package_alt"
            ;;
        zypper)
            sudo zypper install -y "$package_alt"
            ;;
        brew)
            brew install "$package"
            ;;
        *)
            log_error "Unknown package manager"
            return 1
            ;;
    esac
}

update_system() {
    log_step "Updating System Package Lists"

    case $PACKAGE_MANAGER in
        pacman)
            sudo pacman -Sy
            ;;
        apt)
            sudo apt-get update
            ;;
        dnf)
            sudo dnf check-update || true
            ;;
        zypper)
            sudo zypper refresh
            ;;
        brew)
            brew update
            ;;
    esac

    log_success "Package lists updated"
}

# ─────────────────────────────────────────────────────────────────────────────
# Install Core Dependencies
# ─────────────────────────────────────────────────────────────────────────────

install_core_deps() {
    log_step "Installing Core Dependencies"

    local packages=()

    case $PACKAGE_MANAGER in
        pacman)
            packages=(git curl wget unzip tar gzip)
            ;;
        apt)
            packages=(git curl wget unzip tar gzip build-essential)
            ;;
        dnf)
            packages=(git curl wget unzip tar gzip gcc gcc-c++ make)
            ;;
        zypper)
            packages=(git curl wget unzip tar gzip)
            ;;
        brew)
            packages=(git curl wget)
            ;;
    esac

    for pkg in "${packages[@]}"; do
        if ! command_exists "$pkg" 2>/dev/null; then
            log_info "Installing $pkg..."
            install_package "$pkg"
        else
            log_success "$pkg already installed"
        fi
    done
}

# ─────────────────────────────────────────────────────────────────────────────
# Install Zsh
# ─────────────────────────────────────────────────────────────────────────────

install_zsh() {
    log_step "Installing Zsh"

    if command_exists zsh; then
        log_success "Zsh already installed"
    else
        log_info "Installing Zsh..."
        install_package zsh
        log_success "Zsh installed"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Install Oh-My-Zsh
# ─────────────────────────────────────────────────────────────────────────────

install_oh_my_zsh() {
    log_step "Installing Oh-My-Zsh"

    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_success "Oh-My-Zsh already installed"
    else
        log_info "Installing Oh-My-Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        log_success "Oh-My-Zsh installed"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Install Zsh Plugins
# ─────────────────────────────────────────────────────────────────────────────

install_zsh_plugins() {
    log_step "Installing Zsh Plugins"

    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    # zsh-autosuggestions
    if [[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
        log_success "zsh-autosuggestions already installed"
    else
        log_info "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
        log_success "zsh-autosuggestions installed"
    fi

    # zsh-syntax-highlighting
    if [[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
        log_success "zsh-syntax-highlighting already installed"
    else
        log_info "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
        log_success "zsh-syntax-highlighting installed"
    fi

    # zsh-history-substring-search
    if [[ -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search" ]]; then
        log_success "zsh-history-substring-search already installed"
    else
        log_info "Installing zsh-history-substring-search..."
        git clone https://github.com/zsh-users/zsh-history-substring-search "$ZSH_CUSTOM/plugins/zsh-history-substring-search"
        log_success "zsh-history-substring-search installed"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Install Neovim
# ─────────────────────────────────────────────────────────────────────────────

install_neovim() {
    log_step "Installing Neovim"

    if command_exists nvim; then
        local nvim_version
        nvim_version=$(nvim --version | head -1)
        log_success "Neovim already installed: $nvim_version"
    else
        log_info "Installing Neovim..."

        case $PACKAGE_MANAGER in
            pacman)
                sudo pacman -S --noconfirm --needed neovim
                ;;
            apt)
                # Use the PPA for latest Neovim on Debian/Ubuntu
                if ! grep -q "neovim-ppa/unstable" /etc/apt/sources.list.d/* 2>/dev/null; then
                    sudo apt-get install -y software-properties-common
                    sudo add-apt-repository -y ppa:neovim-ppa/unstable
                    sudo apt-get update
                fi
                sudo apt-get install -y neovim
                ;;
            dnf)
                sudo dnf install -y neovim
                ;;
            zypper)
                sudo zypper install -y neovim
                ;;
            brew)
                brew install neovim
                ;;
        esac

        log_success "Neovim installed"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Install Kitty Terminal
# ─────────────────────────────────────────────────────────────────────────────

install_kitty() {
    log_step "Installing Kitty Terminal"

    if command_exists kitty; then
        log_success "Kitty already installed"
    else
        log_info "Installing Kitty..."

        case $PACKAGE_MANAGER in
            pacman)
                sudo pacman -S --noconfirm --needed kitty
                ;;
            apt)
                sudo apt-get install -y kitty
                ;;
            dnf)
                sudo dnf install -y kitty
                ;;
            zypper)
                sudo zypper install -y kitty
                ;;
            brew)
                brew install --cask kitty
                ;;
        esac

        log_success "Kitty installed"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Install Modern CLI Tools
# ─────────────────────────────────────────────────────────────────────────────

install_cli_tools() {
    log_step "Installing Modern CLI Tools"

    # eza/exa (modern ls replacement)
    if command_exists eza || command_exists exa; then
        log_success "eza/exa already installed"
    else
        log_info "Installing eza (modern ls)..."
        case $PACKAGE_MANAGER in
            pacman)
                sudo pacman -S --noconfirm --needed eza
                ;;
            apt)
                # eza might not be in default repos, try installing
                sudo apt-get install -y eza 2>/dev/null || sudo apt-get install -y exa 2>/dev/null || log_warning "eza/exa not available in repos"
                ;;
            dnf)
                sudo dnf install -y eza 2>/dev/null || sudo dnf install -y exa 2>/dev/null || log_warning "eza/exa not available"
                ;;
            brew)
                brew install eza
                ;;
            *)
                log_warning "eza not available for this OS"
                ;;
        esac
    fi

    # bat (modern cat replacement)
    if command_exists bat || command_exists batcat; then
        log_success "bat already installed"
    else
        log_info "Installing bat (modern cat)..."
        case $PACKAGE_MANAGER in
            pacman)
                sudo pacman -S --noconfirm --needed bat
                ;;
            apt)
                sudo apt-get install -y bat
                # On Ubuntu/Debian, bat is installed as batcat
                if command_exists batcat && ! command_exists bat; then
                    mkdir -p "$HOME/.local/bin"
                    ln -sf "$(which batcat)" "$HOME/.local/bin/bat"
                fi
                ;;
            dnf)
                sudo dnf install -y bat
                ;;
            brew)
                brew install bat
                ;;
        esac
    fi

    # fd (modern find replacement)
    if command_exists fd || command_exists fdfind; then
        log_success "fd already installed"
    else
        log_info "Installing fd (modern find)..."
        case $PACKAGE_MANAGER in
            pacman)
                sudo pacman -S --noconfirm --needed fd
                ;;
            apt)
                sudo apt-get install -y fd-find
                # On Ubuntu/Debian, fd is installed as fdfind
                if command_exists fdfind && ! command_exists fd; then
                    mkdir -p "$HOME/.local/bin"
                    ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
                fi
                ;;
            dnf)
                sudo dnf install -y fd-find
                ;;
            brew)
                brew install fd
                ;;
        esac
    fi

    # fzf (fuzzy finder)
    if command_exists fzf; then
        log_success "fzf already installed"
    else
        log_info "Installing fzf (fuzzy finder)..."
        case $PACKAGE_MANAGER in
            pacman)
                sudo pacman -S --noconfirm --needed fzf
                ;;
            apt)
                sudo apt-get install -y fzf
                ;;
            dnf)
                sudo dnf install -y fzf
                ;;
            brew)
                brew install fzf
                ;;
        esac
    fi

    # ripgrep (modern grep replacement)
    if command_exists rg; then
        log_success "ripgrep already installed"
    else
        log_info "Installing ripgrep (modern grep)..."
        case $PACKAGE_MANAGER in
            pacman)
                sudo pacman -S --noconfirm --needed ripgrep
                ;;
            apt)
                sudo apt-get install -y ripgrep
                ;;
            dnf)
                sudo dnf install -y ripgrep
                ;;
            brew)
                brew install ripgrep
                ;;
        esac
    fi

    log_success "CLI tools installation complete"
}

# ─────────────────────────────────────────────────────────────────────────────
# Install Nerd Fonts
# ─────────────────────────────────────────────────────────────────────────────

install_nerd_fonts() {
    log_step "Installing Nerd Fonts (FiraCode)"

    local FONT_DIR
    if [[ "$OS" == "macos" ]]; then
        FONT_DIR="$HOME/Library/Fonts"
    else
        FONT_DIR="$HOME/.local/share/fonts"
    fi

    # Check if FiraCode Nerd Font is already installed
    if fc-list 2>/dev/null | grep -qi "FiraCode.*Nerd" || [[ -f "$FONT_DIR/FiraCodeNerdFont-Regular.ttf" ]]; then
        log_success "FiraCode Nerd Font already installed"
        return 0
    fi

    # For Arch, use the AUR package or official repos
    if [[ "$PACKAGE_MANAGER" == "pacman" ]]; then
        if pacman -Qi ttf-firacode-nerd &>/dev/null; then
            log_success "FiraCode Nerd Font already installed via pacman"
            return 0
        fi
        log_info "Installing FiraCode Nerd Font via pacman..."
        sudo pacman -S --noconfirm --needed ttf-firacode-nerd
        log_success "FiraCode Nerd Font installed"
        return 0
    fi

    # For other systems, download from GitHub
    log_info "Downloading FiraCode Nerd Font..."
    mkdir -p "$FONT_DIR"

    local TEMP_DIR
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    curl -fLo "FiraCode.zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"
    unzip -q "FiraCode.zip" -d "$FONT_DIR"
    rm -rf "$TEMP_DIR"

    # Refresh font cache
    if command_exists fc-cache; then
        fc-cache -fv "$FONT_DIR" >/dev/null 2>&1
    fi

    cd "$DOTFILES_DIR"
    log_success "FiraCode Nerd Font installed"
}

# ─────────────────────────────────────────────────────────────────────────────
# Create Symlinks
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

    # Ensure parent directory exists
    local parent_dir
    parent_dir="$(dirname "$dest")"
    if [[ ! -d "$parent_dir" ]]; then
        mkdir -p "$parent_dir"
    fi

    if [[ -e "$dest" ]] || [[ -L "$dest" ]]; then
        log_info "Removing existing $dest"
        run_cmd rm -rf "$dest"
    fi

    log_info "Linking $src -> $dest"
    run_cmd ln -s "$src" "$dest"
    log_success "Linked: $(basename "$dest")"
}

create_symlinks() {
    log_step "Creating Symlinks"

    # Neovim config
    link_config "$NVIM_SRC" "$NVIM_DEST"

    # Kitty config
    link_config "$KITTY_SRC" "$KITTY_DEST"

    # Zsh config
    link_config "$ZSH_SRC" "$ZSH_DEST"

    # Nginx site script (optional)
    if [[ -f "$NGINX_SITE_SRC" ]]; then
        link_config "$NGINX_SITE_SRC" "$NGINX_SITE_DEST"
        sudo chmod +x "$NGINX_SITE_DEST" 2>/dev/null || true
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Set Zsh as Default Shell
# ─────────────────────────────────────────────────────────────────────────────

set_default_shell() {
    log_step "Setting Zsh as Default Shell"

    local current_shell
    current_shell=$(basename "$SHELL")

    if [[ "$current_shell" == "zsh" ]]; then
        log_success "Zsh is already the default shell"
    else
        log_info "Changing default shell to Zsh..."
        local zsh_path
        zsh_path=$(which zsh)

        # Make sure zsh is in /etc/shells
        if ! grep -q "$zsh_path" /etc/shells 2>/dev/null; then
            echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
        fi

        chsh -s "$zsh_path"
        log_success "Default shell changed to Zsh (takes effect on next login)"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Install NVM (Node Version Manager)
# ─────────────────────────────────────────────────────────────────────────────

install_nvm() {
    log_step "Installing NVM (Node Version Manager)"

    export NVM_DIR="$HOME/.config/nvm"

    if [[ -d "$NVM_DIR" ]] && [[ -s "$NVM_DIR/nvm.sh" ]]; then
        log_success "NVM already installed"
    else
        log_info "Installing NVM..."
        mkdir -p "$NVM_DIR"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
        log_success "NVM installed"
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

    # Detect OS
    detect_os

    if [[ "$OS" == "unknown" ]]; then
        log_error "Could not detect OS. Please install dependencies manually."
        exit 1
    fi

    # Check for Homebrew on macOS
    if [[ "$OS" == "macos" ]] && ! command_exists brew; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Run installation steps
    update_system
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

# Run main function
main "$@"
