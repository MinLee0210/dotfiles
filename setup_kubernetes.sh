#!/bin/bash

# Install kubectl and minikube.
# macOS installs via Homebrew, Linux downloads the official binaries.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

install_linux() {
    local arch
    case "$(detect_arch)" in
        x86_64) arch="amd64" ;;
        arm64)  arch="arm64" ;;
        *)
            print_error "Unsupported architecture: $(uname -m)"
            return 1
            ;;
    esac

    local tmp_dir
    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "$tmp_dir"' RETURN

    # 1. kubectl
    if command_exists kubectl; then
        print_warning "kubectl is already installed, skipping..."
    else
        print_status "Installing kubectl..."
        local version
        version="$(curl -L -s https://dl.k8s.io/release/stable.txt)"
        download_file "https://dl.k8s.io/release/$version/bin/linux/$arch/kubectl" "$tmp_dir/kubectl" || return 1
        download_file "https://dl.k8s.io/release/$version/bin/linux/$arch/kubectl.sha256" "$tmp_dir/kubectl.sha256" || return 1
        (cd "$tmp_dir" && echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check) || return 1
        sudo install -o root -g root -m 0755 "$tmp_dir/kubectl" /usr/local/bin/kubectl
        print_success "kubectl installed"
    fi

    # 2. minikube
    if command_exists minikube; then
        print_warning "minikube is already installed, skipping..."
    else
        print_status "Installing minikube..."
        download_file "https://storage.googleapis.com/minikube/releases/latest/minikube-linux-$arch" "$tmp_dir/minikube" || return 1
        sudo install -m 0755 "$tmp_dir/minikube" /usr/local/bin/minikube
        print_success "minikube installed"
    fi
}

install_macos() {
    require_brew || return 1
    command_exists kubectl  || brew install kubectl
    command_exists minikube || brew install minikube
}

main() {
    case "$(detect_os)" in
        linux) install_linux ;;
        macos) install_macos ;;
        *)
            print_error "Unsupported OS: $(uname -s)"
            return 1
            ;;
    esac || return 1

    kubectl version --client
}

main "$@"
