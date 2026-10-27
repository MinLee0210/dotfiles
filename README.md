# Dotfiles

Personal terminal setup for macOS and Ubuntu: tmux, WezTerm, Starship, plus a few dev tools.

## What's inside

| File | Purpose |
|---|---|
| `.tmux.conf` | tmux config (prefix `C-s`, vim-style panes, Catppuccin mocha theme) |
| `.wezterm.lua` | WezTerm config (bottom tab bar, status plugin) |
| `starship.toml` | Starship prompt |
| `lib.sh` | Shared helpers sourced by the scripts |

## Install

```sh
./setup.sh --dry-run   # list what would run
./setup.sh             # run everything
```

`setup.sh` runs these in order; each can also be run on its own:

1. `setup_utils.sh`: eza, bandwhich (Homebrew on macOS, snap on Linux)
2. `setup_tools.sh`: miniconda, rust, uv, starship, wezterm
3. `setup_tmux.sh`: TPM, then the plugins declared in `.tmux.conf`
4. `setup_kubernetes.sh`: kubectl, minikube
5. `setup_links.sh`: symlinks the configs into `~`

`setup_links.sh` links `.tmux.conf` to `~/.tmux.conf`, `starship.toml` to `~/.config/starship.toml` and
`.wezterm.lua` to `~/.wezterm.lua`. Anything already at those paths is moved to `<name>.bak.<timestamp>`.

## Requirements

- macOS: [Homebrew](https://brew.sh), `git`, `tmux`, `curl`
- Ubuntu: `git`, `tmux`, `curl`, `snapd`
