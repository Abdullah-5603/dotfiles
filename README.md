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

The setup script auto-detects and supports:

- Arch Linux (`pacman`)
- Debian/Ubuntu (`apt`)
- Fedora/RHEL (`dnf`)
- openSUSE (`zypper`)
- macOS (`brew`)

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

System cleanup helper (primarily Arch-focused), including package caches, journals, and common dev caches:

```bash
sudo cleanup
```

## Repository structure

```text
.
├── setup.sh
├── neovim/        # Neovim configuration
├── kitty/         # Kitty terminal configuration
├── scripts/
│   ├── zshrc
│   ├── nginx-site.sh
│   └── cleanup.sh
└── omarchy/       # Theme integration assets
```

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

