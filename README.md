# Abdullah's Dotfiles

A practical, batteries-included developer environment focused on **Neovim + Kitty + Zsh** with one-command setup and sane defaults.

## What this repo includes

| Area | What you get |
| --- | --- |
| Shell | Zsh + Oh-My-Zsh, autosuggestions, syntax highlighting, history substring search |
| Editor | Neovim config (lazy.nvim-based plugin setup, LSP/tools, UI plugins) |
| Terminal | Kitty config (Nerd Font-ready, theme include, polished defaults) |
| CLI tools | eza/exa, bat, fd/fdfind, fzf, ripgrep |
| Fonts | FiraCode Nerd Font installation |
| Extras | `nginx-site` helper and `cleanup` utility script |

## Quick start

```bash
git clone https://github.com/Abdullah-5603/dotfiles.git
cd dotfiles
chmod +x setup.sh
./setup.sh
```

## Supported platforms

`setup.sh` auto-detects your distribution from `/etc/os-release` (using both
`ID` and `ID_LIKE`, so derivatives like Linux Mint, Pop!_OS, EndeavourOS, Rocky,
etc. are matched to their parent family). If detection is inconclusive it falls
back to probing for an installed package manager.

| Family | Package manager | Examples |
| --- | --- | --- |
| Arch | `pacman` | Arch, Manjaro, EndeavourOS, Omarchy |
| Debian | `apt` | Debian, Ubuntu, Linux Mint, Pop!_OS |
| RHEL | `dnf` / `yum` | Fedora, RHEL, CentOS, Rocky, Alma |
| SUSE | `zypper` | openSUSE Leap/Tumbleweed |
| Alpine | `apk` | Alpine |
| macOS | `brew` | macOS |

If a tool isn't available in your distro's repositories, setup logs a warning
and continues (best-effort) rather than failing.

## What `setup.sh` does

It installs and configures your development environment end-to-end:

1. Updates package metadata
2. Installs core dependencies (git, curl, wget, unzip, etc.)
3. Installs Zsh + Oh-My-Zsh + plugins
4. Installs Neovim and Kitty
5. Installs modern CLI tools (eza, bat, fd, fzf, ripgrep)
6. Installs FiraCode Nerd Font
7. Installs NVM
8. Creates symlinks:
   - `~/.config/nvim -> <repo>/neovim`
   - `~/.config/kitty -> <repo>/kitty`
   - `~/.zshrc -> <repo>/scripts/zshrc`
9. Optionally links:
   - `/usr/local/bin/nginx-site`
   - `/usr/local/bin/cleanup`
10. Sets Zsh as default shell

## Useful scripts

### `nginx-site`

Manage Nginx virtual hosts with commands like:

```bash
sudo nginx-site add myapp.test --root ~/websites/myapp
sudo nginx-site secure myapp.test --mkcert
sudo nginx-site list
sudo nginx-site remove myapp.test --purge-root
```

### `cleanup`

Cross-distro system cleanup helper. Detects your package manager and trims its
cache + removes orphans (pacman/apt/dnf/yum/zypper/apk/brew), then clears common
dev caches (pip, Go, pnpm, Docker, JetBrains), browser caches, thumbnails, and
vacuums the systemd journal:

```bash
cleanup
```

## Repository structure

```text
.
├── setup.sh       # Cross-distro installer (auto-detects package manager)
├── neovim/        # Neovim configuration
├── kitty/         # Kitty terminal configuration
├── scripts/
│   ├── zshrc      # Portable zsh config (uses $HOME, no hardcoded paths)
│   ├── nginx-site.sh
│   └── cleanup.sh
└── omarchy/       # Theme integration assets
```

### Per-machine overrides

`scripts/zshrc` sources `~/.zshrc.local` at the end if it exists. Put any
machine-specific PATH entries, secrets, or personal aliases there so they stay
out of the tracked, portable config.

## Updating

Because configs are symlinked, updates are straightforward:

```bash
cd ~/dotfiles
git pull
```

Restart your terminal and Neovim to pick up changes.

## Notes

- The setup script may prompt for `sudo` where required.
- Existing config targets are replaced by symlinks during setup.
- On first Neovim launch, plugins are installed automatically by lazy.nvim.

