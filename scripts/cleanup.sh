#!/usr/bin/env bash
# ============================================================
#  cleanup.sh — cross-distro system cleanup script
#  Auto-detects the package manager and cleans package caches,
#  orphans, dev caches, journals, and thumbnails accordingly.
#
#  Usage: chmod +x cleanup.sh && ./cleanup.sh
#  Weekly cron example:
#    0 9 * * 0 /usr/local/bin/cleanup >> "$HOME/.cleanup.log" 2>&1
# ============================================================

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

section()  { echo -e "\n${CYAN}${BOLD}▶ $1${RESET}"; }
done_msg() { echo -e "${GREEN}✓ $1${RESET}"; }
info()     { echo -e "${YELLOW}→ $1${RESET}"; }

cmd_exists() { command -v "$1" >/dev/null 2>&1; }

# Use sudo only when not already root and sudo is available.
SUDO=""
if [[ $EUID -ne 0 ]] && cmd_exists sudo; then
    SUDO="sudo"
fi

# ── Detect package manager ──────────────────────────────────
PKG="unknown"
if cmd_exists pacman;   then PKG="pacman"
elif cmd_exists apt-get; then PKG="apt"
elif cmd_exists dnf;     then PKG="dnf"
elif cmd_exists yum;     then PKG="yum"
elif cmd_exists zypper;  then PKG="zypper"
elif cmd_exists apk;     then PKG="apk"
elif cmd_exists brew;    then PKG="brew"
fi

echo -e "${BOLD}╔══════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║        System Cleanup Script         ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════╝${RESET}"
info "Package manager: $PKG"

BEFORE=$(df -h / | awk 'NR==2{print $3}')
info "Disk used before: $BEFORE"

# ── 1. Package manager cache + orphans ──────────────────────
section "Cleaning package manager cache & orphans"
case "$PKG" in
    pacman)
        # AUR helper caches
        for h in yay paru; do
            [[ -d "$HOME/.cache/$h" ]] && { rm -rf "$HOME/.cache/$h"; done_msg "$h cache cleared"; }
        done
        if cmd_exists paccache; then
            $SUDO paccache -rk1
            done_msg "pacman cache trimmed (kept last 1 version)"
        else
            info "paccache not found (install pacman-contrib for cache trimming)"
            $SUDO pacman -Sc --noconfirm || true
        fi
        ORPHANS=$(pacman -Qtdq 2>/dev/null || true)
        if [[ -n "$ORPHANS" ]]; then
            echo "$ORPHANS" | $SUDO pacman -Rns --noconfirm - && done_msg "Orphans removed"
        else
            info "No orphaned packages found"
        fi
        ;;
    apt)
        $SUDO apt-get autoremove -y && done_msg "Unused packages removed"
        $SUDO apt-get autoclean -y && done_msg "Stale apt cache cleaned"
        $SUDO apt-get clean && done_msg "apt cache cleared"
        ;;
    dnf)
        $SUDO dnf autoremove -y && done_msg "Unused packages removed"
        $SUDO dnf clean all && done_msg "dnf cache cleared"
        ;;
    yum)
        $SUDO yum autoremove -y || true
        $SUDO yum clean all && done_msg "yum cache cleared"
        ;;
    zypper)
        $SUDO zypper clean --all && done_msg "zypper cache cleared"
        ;;
    apk)
        $SUDO apk cache clean 2>/dev/null && done_msg "apk cache cleaned" || info "apk cache clean unavailable"
        ;;
    brew)
        brew autoremove && done_msg "Unused formulae removed"
        brew cleanup -s && done_msg "Homebrew cache cleared"
        ;;
    *)
        info "Unknown package manager — skipping package cache cleanup"
        ;;
esac

# ── 2. pip cache ─────────────────────────────────────────────
section "Cleaning pip cache"
if cmd_exists pip; then
    pip cache purge && done_msg "pip cache cleared"
fi

# ── 3. Browser caches ────────────────────────────────────────
section "Cleaning browser caches"
for dir in BraveSoftware chromium mozilla Google; do
    TARGET="$HOME/.cache/$dir"
    [[ -d "$TARGET" ]] && { rm -rf "$TARGET"; done_msg "$dir cache cleared"; }
done

# ── 4. systemd journal logs ──────────────────────────────────
section "Vacuuming systemd journal (keeping 200MB)"
if cmd_exists journalctl; then
    $SUDO journalctl --vacuum-size=200M && done_msg "Journal trimmed"
else
    info "journalctl not present — skipping"
fi

# ── 5. Thumbnail cache ───────────────────────────────────────
section "Clearing thumbnail cache"
rm -rf "$HOME/.cache/thumbnails"
done_msg "Thumbnails cleared"

# ── 6. Go build cache ────────────────────────────────────────
section "Cleaning Go build cache"
if cmd_exists go; then
    go clean -cache && done_msg "Go build cache cleared"
elif [[ -d "$HOME/.cache/go-build" ]]; then
    rm -rf "$HOME/.cache/go-build" && done_msg "Go build cache cleared (manual)"
fi

# ── 7. pnpm cache ────────────────────────────────────────────
section "Cleaning pnpm cache"
if cmd_exists pnpm; then
    pnpm store prune && done_msg "pnpm store pruned"
fi

# ── 8. Docker cleanup ────────────────────────────────────────
section "Docker cleanup"
if cmd_exists docker; then
    docker system prune -f && done_msg "Docker pruned (stopped containers + dangling images)"
else
    info "Docker not present, skipping"
fi

# ── 9. JetBrains cache ───────────────────────────────────────
section "Cleaning JetBrains cache"
if [[ -d "$HOME/.cache/JetBrains" ]]; then
    rm -rf "$HOME/.cache/JetBrains" && done_msg "JetBrains cache cleared"
fi

# ── 10. Flatpak unused runtimes ──────────────────────────────
section "Removing unused Flatpak runtimes"
if cmd_exists flatpak; then
    flatpak uninstall --unused -y && done_msg "Flatpak unused runtimes removed"
fi

# ── Summary ──────────────────────────────────────────────────
AFTER=$(df -h / | awk 'NR==2{print $3}')
echo ""
echo -e "${BOLD}╔══════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║             Cleanup Done!            ║${RESET}"
echo -e "${BOLD}╠══════════════════════════════════════╣${RESET}"
echo -e "║  Before : ${YELLOW}$BEFORE${RESET}"
echo -e "║  After  : ${GREEN}$AFTER${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════╝${RESET}"
