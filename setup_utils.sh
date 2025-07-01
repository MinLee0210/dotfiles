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

# Function to check if snap is installed
check_snap() {
    if command_exists snap; then
        print_success "Snap is already installed"
        return 0
    else
        print_error "Snap is not installed. Please install snapd first."
        return 1
    fi
}

# Function to install a package via snap
install_snap_package() {
    local package_name="$1"
    local channel="${2:-stable}"
    
    print_status "Installing $package_name via snap..."
    
    if command_exists "$package_name"; then
        print_warning "$package_name is already installed"
        return 0
    fi
    
    if sudo snap install "$package_name" --channel="$channel"; then
        print_success "$package_name installed successfully"
        return 0
    else
        print_error "Failed to install $package_name"
        return 1
    fi
}

# Function to install eza (modern ls replacement)
install_eza() {
    print_status "Setting up eza (modern ls replacement)..."
    
    if ! check_snap; then
        return 1
    fi
    
    install_snap_package "eza"
}

# Function to install bandwhich (network bandwidth monitor)
install_bandwhich() {
    print_status "Setting up bandwhich (network bandwidth monitor)..."
    
    if ! check_snap; then
        return 1
    fi
    
    install_snap_package "bandwhich"
}

# Function to install both tools
install_all_snap_tools() {
    print_status "Installing snap tools: eza and bandwhich"
    
    if ! check_snap; then
        print_error "Cannot proceed without snap. Please install snapd first."
        return 1
    fi
    
    local success_count=0
    local total_count=2
    
    if install_eza; then
        ((success_count++))
    fi
    
    if install_bandwhich; then
        ((success_count++))
    fi
    
    if [ $success_count -eq $total_count ]; then
        print_success "All snap tools installed successfully!"
        print_status "You may need to restart your shell or run 'source ~/.bashrc' to use the new commands"
    else
        print_warning "Some installations failed. Successfully installed $success_count/$total_count tools"
    fi
}

# Main function
main() {
    print_status "Starting snap tools installation..."
    install_all_snap_tools
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi



