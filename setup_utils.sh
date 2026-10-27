#!/bin/bash

# CLI utilities: eza (modern ls) and bandwhich (bandwidth monitor).
# macOS installs via Homebrew, Linux via snap.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# Install a package with the platform's package manager
install_package() {
    local name="$1"

    if command_exists "$name"; then
        print_warning "$name is already installed"
        return 0
    fi

    print_status "Installing $name..."
    case "$(detect_os)" in
        macos)
            require_brew || return 1
            brew install "$name"
            ;;
        linux)
            if ! command_exists snap; then
                print_error "snap is not installed. Please install snapd first."
                return 1
            fi
            sudo snap install "$name"
            ;;
        *)
            print_error "Unsupported OS: $(uname -s)"
            return 1
            ;;
    esac

    if [ $? -eq 0 ]; then
        print_success "$name installed successfully"
    else
        print_error "Failed to install $name"
        return 1
    fi
}

# Alias ls to eza in the shell rc files (guarded, so ls still works if eza goes missing)
setup_eza_alias() {
    local line="command -v eza >/dev/null 2>&1 && alias ls='eza'"

    append_once "$line" "$HOME/.bashrc"
    # zsh is the macOS default shell, so create .zshrc there if needed
    if [ -f "$HOME/.zshrc" ] || [ "$(detect_os)" = "macos" ]; then
        append_once "$line" "$HOME/.zshrc"
    fi

    print_success "Aliased ls to eza (takes effect in a new shell)"
}

main() {
    print_status "Installing utilities: eza, bandwhich"

    local success_count=0
    local tools=(eza bandwhich)

    for tool in "${tools[@]}"; do
        if install_package "$tool"; then
            success_count=$((success_count + 1))
        fi
    done

    if command_exists eza; then
        setup_eza_alias
    fi

    if [ "$success_count" -eq "${#tools[@]}" ]; then
        print_success "All utilities installed successfully!"
    else
        print_warning "Some installations failed ($success_count/${#tools[@]} succeeded)"
        return 1
    fi
}

main "$@"
