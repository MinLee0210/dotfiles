#!/bin/bash

# Master setup script for dotfiles configuration
# This script runs all setup_*.sh scripts in the correct order

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

print_header() {
    echo -e "\n${CYAN}================================================${NC}"
    echo -e "${CYAN} $1${NC}"
    echo -e "${CYAN}================================================${NC}\n"
}

# Function to check if script exists and is executable
check_script() {
    local script_path="$1"
    
    if [[ ! -f "$script_path" ]]; then
        print_error "Script not found: $script_path"
        return 1
    fi
    
    if [[ ! -x "$script_path" ]]; then
        print_status "Making $script_path executable..."
        chmod +x "$script_path"
    fi
    
    return 0
}

# Function to run a setup script
run_setup_script() {
    local script_name="$1"
    local script_path="$SCRIPT_DIR/$script_name"
    local description="$2"
    
    print_header "$description"
    
    if ! check_script "$script_path"; then
        return 1
    fi
    
    print_status "Running $script_name..."
    
    if bash "$script_path"; then
        print_success "$script_name completed successfully"
        return 0
    else
        print_error "$script_name failed with exit code $?"
        return 1
    fi
}

# Function to display summary
show_summary() {
    local total_scripts="$1"
    local successful_scripts="$2"
    local failed_scripts="$3"
    
    print_header "SETUP SUMMARY"
    
    echo -e "Total scripts: ${CYAN}$total_scripts${NC}"
    echo -e "Successful: ${GREEN}$successful_scripts${NC}"
    echo -e "Failed: ${RED}$failed_scripts${NC}"
    
    if [[ $failed_scripts -eq 0 ]]; then
        print_success "All setup scripts completed successfully!"
        echo -e "\n${GREEN}🎉 Your dotfiles setup is complete!${NC}"
        echo -e "${YELLOW}Note: You may need to restart your shell or run 'source ~/.bashrc' to use new tools${NC}"
    else
        print_warning "Some setup scripts failed. Please check the output above for details."
    fi
}

# Main setup function
main() {
    print_header "DOTFILES SETUP - STARTING ALL CONFIGURATIONS"
    
    # Array of setup scripts in execution order
    # [script_name]="description"
    declare -A setup_scripts=(
        ["setup_utils.sh"]="Utilities and Snap Tools Setup"
        ["setup_tools.sh"]="General Tools Installation"
        ["setup_tmux.sh"]="Tmux Configuration"
        ["setup_kubernetes.sh"]="Kubernetes Tools Setup"
    )
    
    # Execution order (important for dependencies)
    local script_order=(
        "setup_utils.sh"
        "setup_tools.sh"
        "setup_tmux.sh"
        "setup_kubernetes.sh"
    )
    
    local total_scripts=${#script_order[@]}
    local successful_scripts=0
    local failed_scripts=0
    local failed_script_names=()
    
    print_status "Found $total_scripts setup scripts to execute"
    
    # Execute each script in order
    for script_name in "${script_order[@]}"; do
        local description="${setup_scripts[$script_name]}"
        
        if run_setup_script "$script_name" "$description"; then
            ((successful_scripts++))
        else
            ((failed_scripts++))
            failed_script_names+=("$script_name")
        fi
        
        # Add a small delay between scripts
        sleep 1
    done
    
    # Show final summary
    show_summary "$total_scripts" "$successful_scripts" "$failed_scripts"
    
    # List failed scripts if any
    if [[ $failed_scripts -gt 0 ]]; then
        echo -e "\n${RED}Failed scripts:${NC}"
        for failed_script in "${failed_script_names[@]}"; do
            echo -e "  - ${RED}$failed_script${NC}"
        done
        echo -e "\n${YELLOW}You can run individual scripts manually:${NC}"
        for failed_script in "${failed_script_names[@]}"; do
            echo -e "  ${CYAN}./$failed_script${NC}"
        done
    fi
    
    # Exit with appropriate code
    if [[ $failed_scripts -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

# Show help
show_help() {
    echo "Dotfiles Master Setup Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  --dry-run      Show what would be executed without running"
    echo ""
    echo "This script will execute all setup_*.sh scripts in the following order:"
    echo "  1. setup_utils.sh    - Utilities and Snap Tools"
    echo "  2. setup_tools.sh    - General Tools Installation"
    echo "  3. setup_tmux.sh     - Tmux Configuration"
    echo "  4. setup_kubernetes.sh - Kubernetes Tools"
}

# Dry run function
dry_run() {
    print_header "DRY RUN - WHAT WOULD BE EXECUTED"
    
    local script_order=(
        "setup_utils.sh"
        "setup_tools.sh"
        "setup_tmux.sh"
        "setup_kubernetes.sh"
    )
    
    declare -A setup_scripts=(
        ["setup_utils.sh"]="Utilities and Snap Tools Setup"
        ["setup_tools.sh"]="General Tools Installation"
        ["setup_tmux.sh"]="Tmux Configuration"
        ["setup_kubernetes.sh"]="Kubernetes Tools Setup"
    )
    
    echo -e "${CYAN}Execution order:${NC}"
    local counter=1
    for script_name in "${script_order[@]}"; do
        local description="${setup_scripts[$script_name]}"
        local script_path="$SCRIPT_DIR/$script_name"
        
        if [[ -f "$script_path" ]]; then
            echo -e "  ${counter}. ${GREEN}✓${NC} $script_name - $description"
        else
            echo -e "  ${counter}. ${RED}✗${NC} $script_name - $description ${RED}(NOT FOUND)${NC}"
        fi
        ((counter++))
    done
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    --dry-run)
        dry_run
        exit 0
        ;;
    "")
        main "$@"
        ;;
    *)
        print_error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac 