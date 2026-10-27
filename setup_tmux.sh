#!/bin/bash

# Install TPM (Tmux Plugin Manager) and let it install the plugins listed in
# .tmux.conf. The config file itself is linked by setup_links.sh.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

TPM_DIR="$HOME/.tmux/plugins/tpm"

check_dependencies() {
    if ! command_exists git; then
        print_error "git is not installed. Please install git first."
        exit 1
    fi

    if ! command_exists tmux; then
        print_error "tmux is not installed. Please install tmux first."
        exit 1
    fi
}

install_tpm() {
    if [ -d "$TPM_DIR" ]; then
        print_status "TPM already present, updating..."
        git -C "$TPM_DIR" pull --quiet
    else
        print_status "Cloning TPM..."
        git clone --quiet https://github.com/tmux-plugins/tpm.git "$TPM_DIR"
    fi
}

# Plugins come from the @plugin lines in ~/.tmux.conf, so the list lives in one place
install_plugins() {
    if [ ! -f "$HOME/.tmux.conf" ]; then
        print_warning "~/.tmux.conf not found; run setup_links.sh first, then press prefix + I in tmux"
        return 0
    fi

    print_status "Installing tmux plugins via TPM..."
    tmux start-server \; new-session -d -s tpm-install
    "$TPM_DIR/scripts/install_plugins.sh"
    tmux kill-session -t tpm-install 2>/dev/null || true
    print_success "Plugins installed"
}

main() {
    check_dependencies
    install_tpm
    install_plugins

    echo
    print_success "Tmux setup completed!"
    echo -e "${YELLOW}Next:${NC} start tmux and reload the config with ${GREEN}Ctrl+s r${NC}"
}

main "$@"
