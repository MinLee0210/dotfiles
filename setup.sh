#!/bin/bash

# Master setup script: runs every setup_*.sh in order.
# Works on macOS and Ubuntu; compatible with bash 3.2.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# Parallel arrays, in execution order
SCRIPTS=(
    "setup_utils.sh"
    "setup_tools.sh"
    "setup_tmux.sh"
    "setup_kubernetes.sh"
    "setup_links.sh"
)
DESCRIPTIONS=(
    "Utilities (eza, bandwhich)"
    "Development tools (miniconda, rust, uv, starship, ble.sh, zsh plugins, wezterm)"
    "Tmux plugin manager and plugins"
    "Kubernetes tools (kubectl, minikube)"
    "Link config files into place"
)

print_header() {
    echo -e "\n${CYAN}================================================${NC}"
    echo -e "${CYAN} $1${NC}"
    echo -e "${CYAN}================================================${NC}\n"
}

run_setup_script() {
    local script_name="$1"
    local description="$2"
    local script_path="$SCRIPT_DIR/$script_name"

    print_header "$description"

    if [ ! -f "$script_path" ]; then
        print_error "Script not found: $script_path"
        return 1
    fi

    print_status "Running $script_name..."
    if bash "$script_path"; then
        print_success "$script_name completed successfully"
    else
        print_error "$script_name failed"
        return 1
    fi
}

main() {
    print_header "DOTFILES SETUP"

    local failed=()
    local i
    for i in "${!SCRIPTS[@]}"; do
        run_setup_script "${SCRIPTS[$i]}" "${DESCRIPTIONS[$i]}" || failed+=("${SCRIPTS[$i]}")
    done

    print_header "SETUP SUMMARY"
    echo -e "Total: ${CYAN}${#SCRIPTS[@]}${NC}  Failed: ${RED}${#failed[@]}${NC}"

    if [ "${#failed[@]}" -eq 0 ]; then
        print_success "All setup scripts completed successfully!"
        echo -e "${YELLOW}Restart your shell to pick up new tools.${NC}"
        return 0
    fi

    echo -e "\n${YELLOW}Re-run individually:${NC}"
    local name
    for name in "${failed[@]}"; do
        echo -e "  ${CYAN}./$name${NC}"
    done
    return 1
}

show_help() {
    echo "Usage: $0 [--dry-run | -h | --help]"
    echo ""
    echo "Runs, in order:"
    local i
    for i in "${!SCRIPTS[@]}"; do
        echo "  $((i + 1)). ${SCRIPTS[$i]} - ${DESCRIPTIONS[$i]}"
    done
}

dry_run() {
    print_header "DRY RUN - WHAT WOULD BE EXECUTED"

    local i
    for i in "${!SCRIPTS[@]}"; do
        if [ -f "$SCRIPT_DIR/${SCRIPTS[$i]}" ]; then
            echo -e "  $((i + 1)). ${GREEN}✓${NC} ${SCRIPTS[$i]} - ${DESCRIPTIONS[$i]}"
        else
            echo -e "  $((i + 1)). ${RED}✗${NC} ${SCRIPTS[$i]} - ${DESCRIPTIONS[$i]} ${RED}(NOT FOUND)${NC}"
        fi
    done
}

case "${1:-}" in
    -h|--help) show_help ;;
    --dry-run) dry_run ;;
    "")        main ;;
    *)
        print_error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
