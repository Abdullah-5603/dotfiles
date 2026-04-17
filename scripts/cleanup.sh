#!/bin/bash
# ============================================================
#  cleanup.sh — Arch/Omarchy system cleanup script
#  Usage: chmod +x cleanup.sh && ./cleanup.sh
#  Add to crontab for weekly runs:
#    0 9 * * 0 /home/nprime/cleanup.sh >> /home/nprime/.cleanup.log 2>&1
# ============================================================

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

section() { echo -e "\n${CYAN}${BOLD}▶ $1${RESET}"; }
done_msg() { echo -e "${GREEN}✓ $1${RESET}"; }
info() { echo -e "${YELLOW}→ $1${RESET}"; }

echo -e "${BOLD}╔══════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║        System Cleanup Script         ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════╝${RESET}"

BEFORE=$(df -h / | awk 'NR==2{print $3}')
info "Disk used before: $BEFORE"

# ── 1. YAY / AUR cache ──────────────────────────────────────
section "Cleaning yay AUR cache"
if [ -d "$HOME/.cache/yay" ]; then
    rm -rf "$HOME/.cache/yay"
    done_msg "yay cache cleared"
else
    info "yay cache already clean"
fi

# ── 2. Pacman cache (keep last 1 version) ───────────────────
section "Cleaning pacman package cache"
if command -v paccache &>/dev/null; then
    sudo paccache -rk1
    done_msg "pacman cache trimmed (kept last 1 version)"
else
    info "paccache not found, installing pacman-contrib..."
    sudo pacman -S --noconfirm pacman-contrib
    sudo paccache -rk1
    done_msg "pacman cache trimmed"
fi

# ── 3. Orphaned packages ─────────────────────────────────────
section "Removing orphaned packages"
ORPHANS=$(pacman -Qtdq 2>/dev/null || true)
if [ -n "$ORPHANS" ]; then
    echo "$ORPHANS" | sudo pacman -Rns --noconfirm -
    done_msg "Orphans removed"
else
    info "No orphaned packages found"
fi

# ── 4. pip cache ─────────────────────────────────────────────
section "Cleaning pip cache"
if command -v pip &>/dev/null; then
    pip cache purge
    done_msg "pip cache cleared"
fi

# ── 5. Browser caches ────────────────────────────────────────
section "Cleaning browser caches"
for dir in BraveSoftware chromium mozilla Google; do
    TARGET="$HOME/.cache/$dir"
    if [ -d "$TARGET" ]; then
        rm -rf "$TARGET"
        done_msg "$dir cache cleared"
    fi
done

# ── 6. Journal logs ──────────────────────────────────────────
section "Vacuuming systemd journal (keeping 200MB)"
sudo journalctl --vacuum-size=200M
done_msg "Journal trimmed"

# ── 7. Thumbnail cache ───────────────────────────────────────
section "Clearing thumbnail cache"
rm -rf "$HOME/.cache/thumbnails"
done_msg "Thumbnails cleared"

# ── 8. go build cache ────────────────────────────────────────
section "Cleaning Go build cache"
if command -v go &>/dev/null; then
    go clean -cache
    done_msg "Go build cache cleared"
elif [ -d "$HOME/.cache/go-build" ]; then
    rm -rf "$HOME/.cache/go-build"
    done_msg "Go build cache cleared (manual)"
fi

# ── 9. pnpm cache ────────────────────────────────────────────
section "Cleaning pnpm cache"
if command -v pnpm &>/dev/null; then
    pnpm store prune
    done_msg "pnpm store pruned"
fi

# ── 10. Docker cleanup ───────────────────────────────────────
section "Docker cleanup"
if command -v docker &>/dev/null; then
    docker system prune -f
    done_msg "Docker pruned (stopped containers + dangling images)"
else
    info "Docker not running, skipping"
fi

# ── 11. JetBrains cache ──────────────────────────────────────
section "Cleaning JetBrains cache"
if [ -d "$HOME/.cache/JetBrains" ]; then
    rm -rf "$HOME/.cache/JetBrains"
    done_msg "JetBrains cache cleared"
fi

# ── 12. Flatpak unused runtimes ──────────────────────────────
section "Removing unused Flatpak runtimes"
if command -v flatpak &>/dev/null; then
    flatpak uninstall --unused -y
    done_msg "Flatpak unused runtimes removed"
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
