#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
TMUX_PLUGINS_DIR="$HOME/.tmux/plugins"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check dependencies
check_dependencies() {
    print_status "Checking dependencies..."
    
    if ! command_exists git; then
        print_error "git is not installed. Please install git first."
        exit 1
    fi
    
    if ! command_exists tmux; then
        print_warning "tmux is not installed. Please install tmux to use these configurations."
    fi
    
    print_success "Dependencies check completed"
}

# Create necessary directories
create_directories() {
    print_status "Creating directories..."
    
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$TMUX_PLUGINS_DIR"
    
    print_success "Directories created"
}

# Download tmux plugins
download_plugins() {
    print_status "Downloading tmux plugins..."
    
    # Array of plugins to download (repo_url directory_name)
    declare -A plugins=(
        ["https://github.com/tmux-plugins/tpm.git"]="tpm"
        ["https://github.com/tmux-plugins/tmux-resurrect.git"]="tmux-resurrect"
        ["https://github.com/tmux-plugins/tmux-continuum.git"]="tmux-continuum"
        ["https://github.com/christoomey/vim-tmux-navigator.git"]="vim-tmux-navigator"
        ["https://github.com/catppuccin/tmux.git"]="catppuccin-tmux"
    )
    
    for repo_url in "${!plugins[@]}"; do
        plugin_name="${plugins[$repo_url]}"
        plugin_dir="$TMUX_PLUGINS_DIR/$plugin_name"
        
        if [ -d "$plugin_dir" ]; then
            print_warning "Plugin $plugin_name already exists, updating..."
            cd "$plugin_dir" && git pull
        else
            print_status "Cloning $plugin_name..."
            git clone "$repo_url" "$plugin_dir"
        fi
        
        if [ $? -eq 0 ]; then
            print_success "Successfully downloaded $plugin_name"
        else
            print_error "Failed to download $plugin_name"
        fi
    done
}

# Setup configuration links
setup_config_links() {
    print_status "Setting up configuration links..."
    
    # Link .tmux.conf
    if [ -f "$SCRIPT_DIR/.tmux.conf" ]; then
        ln -sf "$SCRIPT_DIR/.tmux.conf" "$CONFIG_DIR/tmux.conf"
        ln -sf "$SCRIPT_DIR/.tmux.conf" "$HOME/.tmux.conf"
        print_success "Linked .tmux.conf"
    else
        print_warning ".tmux.conf not found in script directory"
    fi
    
    # Link starship.toml if exists
    if [ -f "$SCRIPT_DIR/starship.toml" ]; then
        ln -sf "$SCRIPT_DIR/starship.toml" "$CONFIG_DIR/starship.toml"
        mkdir -p "$HOME/.config"
        ln -sf "$SCRIPT_DIR/starship.toml" "$HOME/.config/starship.toml"
        print_success "Linked starship.toml"
    fi
    
    # Link catppuccin-tmux directory if exists
    if [ -d "$SCRIPT_DIR/catppuccin-tmux" ]; then
        ln -sf "$SCRIPT_DIR/catppuccin-tmux" "$CONFIG_DIR/catppuccin-tmux"
        print_success "Linked catppuccin-tmux directory"
    fi
    
    # Create symlinks for easy access
    ln -sf "$TMUX_PLUGINS_DIR" "$CONFIG_DIR/tmux-plugins"
    print_success "Created symlink to tmux plugins directory"
}

# Make TPM executable
setup_tpm() {
    print_status "Setting up TPM (Tmux Plugin Manager)..."
    
    tpm_script="$TMUX_PLUGINS_DIR/tpm/tpm"
    if [ -f "$tpm_script" ]; then
        chmod +x "$tpm_script"
        print_success "TPM is ready to use"
        print_status "To install plugins, press 'prefix + I' in tmux (Ctrl+s + I by default)"
    else
        print_error "TPM script not found"
    fi
}

# Install plugins automatically (optional)
install_plugins() {
    print_status "Installing tmux plugins automatically..."
    
    if command_exists tmux; then
        # Start a new tmux session in detached mode and install plugins
        tmux new-session -d -s "plugin-install" 2>/dev/null || true
        tmux send-keys -t "plugin-install" "~/.tmux/plugins/tpm/scripts/install_plugins.sh" Enter 2>/dev/null || true
        sleep 2
        tmux kill-session -t "plugin-install" 2>/dev/null || true
        print_success "Plugins installation attempted"
    else
        print_warning "tmux not available, skipping automatic plugin installation"
        print_status "You can install plugins later by pressing 'prefix + I' in tmux"
    fi
}

# Main function
main() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}  Tmux Configuration Setup Script${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo
    
    check_dependencies
    create_directories
    download_plugins
    setup_config_links
    setup_tpm
    
    echo
    print_success "Setup completed!"
    echo
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Start tmux: ${GREEN}tmux${NC}"
    echo "2. Install plugins: ${GREEN}Ctrl+s + I${NC} (or your prefix + I)"
    echo "3. Reload config: ${GREEN}Ctrl+s + r${NC} (or your prefix + r)"
    echo
    echo -e "${BLUE}Configuration files are linked in:${NC} $CONFIG_DIR"
    echo -e "${BLUE}Tmux plugins are installed in:${NC} $TMUX_PLUGINS_DIR"
    
    # Ask if user wants to install plugins now
    if command_exists tmux; then
        echo
        read -p "Do you want to attempt automatic plugin installation now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_plugins
        fi
    fi
}

# Run main function
main "$@" 