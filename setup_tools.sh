#!/bin/bash

# Development tools: miniconda, rust, uv, starship, wezterm.
# Config files (starship.toml, .wezterm.lua) are linked by setup_links.sh.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

OS="$(detect_os)"
ARCH="$(detect_arch)"

# Scratch space for installers, removed on exit
DOWNLOADS_DIR="$(mktemp -d)"
trap 'rm -rf "$DOWNLOADS_DIR"' EXIT

check_dependencies() {
    print_status "Checking dependencies..."

    if [ "$OS" = "unsupported" ] || [ "$ARCH" = "unsupported" ]; then
        print_error "Unsupported platform: $(uname -s) $(uname -m)"
        exit 1
    fi

    if ! command_exists curl; then
        print_error "curl is not installed. Please install curl first."
        exit 1
    fi

    if ! command_exists tar; then
        print_error "tar is not installed. Please install tar first."
        exit 1
    fi

    print_success "Dependencies check completed"
}

install_miniconda() {
    print_status "Installing Miniconda..."

    if command_exists conda; then
        print_warning "Conda is already installed, skipping..."
        return 0
    fi

    # Miniconda names: Linux-{x86_64,aarch64}, MacOSX-{x86_64,arm64}
    local platform
    case "$OS-$ARCH" in
        linux-x86_64) platform="Linux-x86_64" ;;
        linux-arm64)  platform="Linux-aarch64" ;;
        macos-x86_64) platform="MacOSX-x86_64" ;;
        macos-arm64)  platform="MacOSX-arm64" ;;
    esac

    local installer="$DOWNLOADS_DIR/miniconda.sh"

    print_status "Downloading Miniconda installer..."
    if ! download_file "https://repo.anaconda.com/miniconda/Miniconda3-latest-$platform.sh" "$installer"; then
        print_error "Failed to download Miniconda"
        return 1
    fi

    bash "$installer" -b -p "$HOME/miniconda3" || return 1

    append_once 'export PATH="$HOME/miniconda3/bin:$PATH"' "$HOME/.bashrc"
    [ -f "$HOME/.zshrc" ] && append_once 'export PATH="$HOME/miniconda3/bin:$PATH"' "$HOME/.zshrc"

    print_success "Miniconda installed successfully"
}

install_rust() {
    print_status "Installing Rust..."

    if command_exists rustc; then
        print_warning "Rust is already installed, skipping..."
        return 0
    fi

    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || return 1

    # shellcheck disable=SC1091
    source "$HOME/.cargo/env" 2>/dev/null || true

    print_success "Rust installed successfully"
}

install_uv() {
    print_status "Installing UV (Python package installer)..."

    if command_exists uv; then
        print_warning "UV is already installed, skipping..."
        return 0
    fi

    curl -LsSf https://astral.sh/uv/install.sh | sh || return 1

    print_success "UV installed successfully"
}

install_starship() {
    print_status "Installing Starship prompt..."

    if command_exists starship; then
        print_warning "Starship is already installed, skipping..."
    else
        curl -sS https://starship.rs/install.sh | sh -s -- -y || return 1
        print_success "Starship installed successfully"
    fi

    append_once 'eval "$(starship init bash)"' "$HOME/.bashrc"
    [ -f "$HOME/.zshrc" ] && append_once 'eval "$(starship init zsh)"' "$HOME/.zshrc"
    return 0
}

# Clone a repo into dir, or fast-forward it if already there
clone_or_update() {
    local url="$1"
    local dir="$2"

    if [ -d "$dir/.git" ]; then
        git -C "$dir" pull --quiet
    else
        mkdir -p "$(dirname "$dir")"
        git clone --quiet --depth 1 "$url" "$dir"
    fi
}

# bash: ble.sh (syntax highlighting, autosuggestions, better completion).
# ble.sh must be sourced first with --noattach and attached after everything else
# (including the starship init), otherwise it conflicts with prompt hooks.
install_blesh() {
    print_status "Installing ble.sh (bash)..."

    local blesh="$HOME/.local/share/blesh/ble.sh"
    local src_dir="$DOWNLOADS_DIR/ble.sh"

    if [ ! -f "$blesh" ]; then
        if ! command_exists git || ! command_exists make; then
            print_error "git and make are required to build ble.sh"
            return 1
        fi
        git clone --quiet --recursive --depth 1 --shallow-submodules \
            https://github.com/akinomyoga/ble.sh.git "$src_dir" || return 1
        make -C "$src_dir" install PREFIX="$HOME/.local" >/dev/null || return 1
    else
        print_warning "ble.sh is already installed, skipping build..."
    fi

    prepend_once '[[ $- == *i* ]] && source "$HOME/.local/share/blesh/ble.sh" --noattach' "$HOME/.bashrc"
    append_once '[[ ${BLE_VERSION-} ]] && ble-attach' "$HOME/.bashrc"

    print_success "ble.sh installed and wired into ~/.bashrc"
}

# zsh: autosuggestions + syntax highlighting. zsh-syntax-highlighting must be
# sourced last in .zshrc.
install_zsh_plugins() {
    print_status "Installing zsh plugins..."

    if ! command_exists git; then
        print_error "git is required to install zsh plugins"
        return 1
    fi

    local plugins_dir="$HOME/.zsh/plugins"
    clone_or_update https://github.com/zsh-users/zsh-autosuggestions.git "$plugins_dir/zsh-autosuggestions" || return 1
    clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugins_dir/zsh-syntax-highlighting" || return 1

    append_once 'source "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"' "$HOME/.zshrc"
    append_once 'source "$HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"' "$HOME/.zshrc"

    print_success "zsh plugins installed and wired into ~/.zshrc"
}

install_shell_enhancements() {
    install_blesh || return 1
    install_zsh_plugins
}

install_wezterm() {
    print_status "Installing WezTerm..."

    if command_exists wezterm; then
        print_warning "WezTerm is already installed, skipping..."
        return 0
    fi

    if [ "$OS" = "macos" ]; then
        require_brew || return 1
        brew install --cask wezterm
        return $?
    fi

    if [ "$ARCH" != "x86_64" ]; then
        print_warning "No prebuilt WezTerm binary for $ARCH, trying the x86_64 build anyway..."
    fi

    local wezterm_file="wezterm-nightly-ubuntu20.04.tar.xz"
    local download_path="$DOWNLOADS_DIR/$wezterm_file"

    print_status "Downloading WezTerm..."
    if ! download_file "https://github.com/wez/wezterm/releases/latest/download/$wezterm_file" "$download_path"; then
        print_error "Failed to download WezTerm"
        return 1
    fi

    tar -xf "$download_path" -C "$DOWNLOADS_DIR"

    local extracted_dir
    extracted_dir="$(find "$DOWNLOADS_DIR" -maxdepth 1 -name "wezterm-*" -type d | head -1)"
    if [ -z "$extracted_dir" ]; then
        print_error "Failed to find extracted WezTerm directory"
        return 1
    fi

    local install_dir="$HOME/.local/wezterm"
    mkdir -p "$install_dir" "$HOME/.local/bin"
    cp -r "$extracted_dir"/* "$install_dir/"
    ln -sf "$install_dir/wezterm" "$HOME/.local/bin/wezterm"

    append_once 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc"
    [ -f "$HOME/.zshrc" ] && append_once 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.zshrc"

    print_success "WezTerm installed successfully"
}

main() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}  Development Tools Setup Script${NC}"
    echo -e "${BLUE}  Installing: miniconda, rust, uv, starship, ble.sh, zsh plugins, wezterm${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo

    check_dependencies

    local failed=0
    install_miniconda || failed=$((failed + 1))
    install_rust      || failed=$((failed + 1))
    install_uv        || failed=$((failed + 1))
    install_starship  || failed=$((failed + 1))
    # After starship, so ble-attach lands below the starship init in ~/.bashrc
    install_shell_enhancements || failed=$((failed + 1))
    install_wezterm  || failed=$((failed + 1))

    echo
    if [ "$failed" -eq 0 ]; then
        print_success "Setup completed!"
    else
        print_warning "Setup finished with $failed failed tool(s)"
    fi
    echo -e "${YELLOW}Next:${NC} restart your shell, then check with conda/rustc/uv/starship/wezterm ${GREEN}--version${NC}"

    [ "$failed" -eq 0 ]
}

main "$@"
