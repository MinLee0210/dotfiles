#!/bin/bash

# Symlink the config files in this repo into their expected locations.
# Existing files are backed up (see link_file in lib.sh), never overwritten.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

main() {
    print_status "Linking configuration files..."

    link_file "$SCRIPT_DIR/.tmux.conf"   "$HOME/.tmux.conf"
    link_file "$SCRIPT_DIR/starship.toml" "$HOME/.config/starship.toml"
    link_file "$SCRIPT_DIR/.wezterm.lua"  "$HOME/.wezterm.lua"

    print_success "Configuration links done"
}

main "$@"
