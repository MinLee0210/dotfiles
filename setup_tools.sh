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
DOWNLOADS_DIR="$SCRIPT_DIR/downloads"

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

# Detect system architecture
detect_arch() {
    case $(uname -m) in
        x86_64) echo "x86_64" ;;
        aarch64|arm64) echo "aarch64" ;;
        *) echo "unsupported" ;;
    esac
}

# Check dependencies
check_dependencies() {
    print_status "Checking dependencies..."
    
    if ! command_exists curl && ! command_exists wget; then
        print_error "Neither curl nor wget is installed. Please install one of them first."
        exit 1
    fi
    
    if ! command_exists tar; then
        print_error "tar is not installed. Please install tar first."
        exit 1
    fi
    
    print_success "Dependencies check completed"
}

# Create necessary directories
create_directories() {
    print_status "Creating directories..."
    
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$DOWNLOADS_DIR"
    
    print_success "Directories created"
}

# Download function with fallback
download_file() {
    local url="$1"
    local output="$2"
    
    if command_exists curl; then
        curl -fsSL "$url" -o "$output"
    elif command_exists wget; then
        wget -q "$url" -O "$output"
    else
        print_error "No download tool available"
        return 1
    fi
}

# Install Miniconda
install_miniconda() {
    print_status "Installing Miniconda..."
    
    if command_exists conda; then
        print_warning "Conda is already installed, skipping..."
        return 0
    fi
    
    local arch=$(detect_arch)
    local miniconda_url
    
    case $arch in
        x86_64)
            miniconda_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
            ;;
        aarch64)
            miniconda_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh"
            ;;
        *)
            print_error "Unsupported architecture for Miniconda: $arch"
            return 1
            ;;
    esac
    
    local installer="$DOWNLOADS_DIR/miniconda.sh"
    
    print_status "Downloading Miniconda installer..."
    if download_file "$miniconda_url" "$installer"; then
        chmod +x "$installer"
        print_status "Running Miniconda installer..."
        bash "$installer" -b -p "$HOME/miniconda3"
        
        # Add to PATH
        echo 'export PATH="$HOME/miniconda3/bin:$PATH"' >> "$HOME/.bashrc"
        echo 'export PATH="$HOME/miniconda3/bin:$PATH"' >> "$HOME/.zshrc" 2>/dev/null || true
        
        print_success "Miniconda installed successfully"
        print_status "Please restart your shell or run: source ~/.bashrc"
    else
        print_error "Failed to download Miniconda"
        return 1
    fi
}

# Install Rust
install_rust() {
    print_status "Installing Rust..."
    
    if command_exists rustc; then
        print_warning "Rust is already installed, skipping..."
        return 0
    fi
    
    print_status "Downloading and running rustup installer..."
    if command_exists curl; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    else
        print_error "curl is required for Rust installation"
        return 1
    fi
    
    # Source cargo env
    source "$HOME/.cargo/env" 2>/dev/null || true
    
    print_success "Rust installed successfully"
}

# Install UV
install_uv() {
    print_status "Installing UV (Python package installer)..."
    
    if command_exists uv; then
        print_warning "UV is already installed, skipping..."
        return 0
    fi
    
    print_status "Downloading and installing UV..."
    if command_exists curl; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
    else
        print_error "curl is required for UV installation"
        return 1
    fi
    
    # Add to PATH
    export PATH="$HOME/.cargo/bin:$PATH"
    
    print_success "UV installed successfully"
}

# Install Starship
install_starship() {
    print_status "Installing Starship prompt..."
    
    if command_exists starship; then
        print_warning "Starship is already installed, skipping..."
        return 0
    fi
    
    print_status "Downloading and installing Starship..."
    if command_exists curl; then
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    else
        print_error "curl is required for Starship installation"
        return 1
    fi
    
    print_success "Starship installed successfully"
    
    # Setup starship configuration
    if [ -f "$SCRIPT_DIR/starship.toml" ]; then
        mkdir -p "$HOME/.config"
        ln -sf "$SCRIPT_DIR/starship.toml" "$HOME/.config/starship.toml"
        ln -sf "$SCRIPT_DIR/starship.toml" "$CONFIG_DIR/starship.toml"
        print_success "Linked starship configuration"
    fi
    
    # Add to shell configs
    print_status "Adding Starship to shell configurations..."
    
    # Bash
    if ! grep -q "starship init bash" "$HOME/.bashrc" 2>/dev/null; then
        echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
    fi
    
    # Zsh
    if [ -f "$HOME/.zshrc" ]; then
        if ! grep -q "starship init zsh" "$HOME/.zshrc" 2>/dev/null; then
            echo 'eval "$(starship init zsh)"' >> "$HOME/.zshrc"
        fi
    fi
}

# Install WezTerm
install_wezterm() {
    print_status "Installing WezTerm..."
    
    if command_exists wezterm; then
        print_warning "WezTerm is already installed, skipping..."
        return 0
    fi
    
    local arch=$(detect_arch)
    local wezterm_url
    local wezterm_file
    
    case $arch in
        x86_64)
            wezterm_url="https://github.com/wez/wezterm/releases/latest/download/wezterm-nightly-ubuntu20.04.tar.xz"
            wezterm_file="wezterm-nightly-ubuntu20.04.tar.xz"
            ;;
        aarch64)
            print_warning "WezTerm ARM64 binaries may not be available, trying x86_64 version..."
            wezterm_url="https://github.com/wez/wezterm/releases/latest/download/wezterm-nightly-ubuntu20.04.tar.xz"
            wezterm_file="wezterm-nightly-ubuntu20.04.tar.xz"
            ;;
        *)
            print_error "Unsupported architecture for WezTerm: $arch"
            return 1
            ;;
    esac
    
    local download_path="$DOWNLOADS_DIR/$wezterm_file"
    
    print_status "Downloading WezTerm..."
    if download_file "$wezterm_url" "$download_path"; then
        print_status "Extracting WezTerm..."
        cd "$DOWNLOADS_DIR"
        tar -xf "$wezterm_file"
        
        # Find the extracted directory
        local extracted_dir=$(find . -name "wezterm-*" -type d | head -1)
        
        if [ -n "$extracted_dir" ]; then
            # Install to /opt or local directory
            local install_dir="$HOME/.local/wezterm"
            mkdir -p "$install_dir"
            cp -r "$extracted_dir"/* "$install_dir/"
            
            # Create symlink in PATH
            mkdir -p "$HOME/.local/bin"
            ln -sf "$install_dir/wezterm" "$HOME/.local/bin/wezterm"
            
            # Add to PATH if not already there
            if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc" 2>/dev/null || true
            fi
            
            print_success "WezTerm installed successfully"
        else
            print_error "Failed to find extracted WezTerm directory"
            return 1
        fi
    else
        print_error "Failed to download WezTerm"
        return 1
    fi
}

# Setup configuration links
setup_config_links() {
    print_status "Setting up configuration links..."
    
    # Create a summary file
    cat > "$CONFIG_DIR/installed_tools.txt" << EOF
Installed Tools Summary
======================
Generated on: $(date)

Tools installed:
- Miniconda: $(command_exists conda && echo "✓ Installed" || echo "✗ Not found")
- Rust: $(command_exists rustc && echo "✓ Installed ($(rustc --version 2>/dev/null || echo "version unknown"))" || echo "✗ Not found")
- UV: $(command_exists uv && echo "✓ Installed" || echo "✗ Not found")
- Starship: $(command_exists starship && echo "✓ Installed" || echo "✗ Not found")
- WezTerm: $(command_exists wezterm && echo "✓ Installed" || echo "✗ Not found")

Configuration files:
$(find "$CONFIG_DIR" -type f -name "*.toml" -o -name "*.conf" | sort)

Installation directories:
- Miniconda: ~/miniconda3
- Rust: ~/.cargo
- Starship config: ~/.config/starship.toml
- WezTerm: ~/.local/wezterm

EOF
    
    print_success "Configuration summary created"
}

# Main installation function
main() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}  Development Tools Setup Script${NC}"
    echo -e "${BLUE}  Installing: miniconda, rust, uv, starship, wezterm${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo
    
    check_dependencies
    create_directories
    
    # Install tools
    install_miniconda
    install_rust
    install_uv
    install_starship
    install_wezterm
    
    setup_config_links
    
    echo
    print_success "Setup completed!"
    echo
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Restart your shell or run: ${GREEN}source ~/.bashrc${NC}"
    echo "2. Verify installations:"
    echo "   - ${GREEN}conda --version${NC}"
    echo "   - ${GREEN}rustc --version${NC}"
    echo "   - ${GREEN}uv --version${NC}"
    echo "   - ${GREEN}starship --version${NC}"
    echo "   - ${GREEN}wezterm --version${NC}"
    echo
    echo -e "${BLUE}Configuration files are in:${NC} $CONFIG_DIR"
    echo -e "${BLUE}Downloads are in:${NC} $DOWNLOADS_DIR"
    echo
    echo -e "${YELLOW}Note:${NC} Some tools may require a shell restart to be available in PATH"
}

# Run main function
main "$@" 