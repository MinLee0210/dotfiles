#!/bin/bash
# Shared helpers, sourced by setup*.sh. Compatible with bash 3.2 (macOS default).

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_status()  { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Prints: macos | linux | unsupported
detect_os() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux)  echo "linux" ;;
        *)      echo "unsupported" ;;
    esac
}

# Prints: x86_64 | arm64 | unsupported
detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64)  echo "x86_64" ;;
        aarch64|arm64) echo "arm64" ;;
        *)             echo "unsupported" ;;
    esac
}

# Fail early (with a hint) when a macOS install needs Homebrew
require_brew() {
    if ! command_exists brew; then
        print_error "Homebrew is required on macOS. Install it from https://brew.sh first."
        return 1
    fi
}

download_file() {
    local url="$1"
    local output="$2"

    if command_exists curl; then
        curl -fsSL "$url" -o "$output"
    elif command_exists wget; then
        wget -q "$url" -O "$output"
    else
        print_error "Neither curl nor wget is available"
        return 1
    fi
}

# Append a line to a file unless it is already there
append_once() {
    local line="$1"
    local file="$2"

    touch "$file"
    grep -qxF "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

# Symlink src to dst. An existing file or foreign symlink at dst is moved aside
# to dst.bak.<timestamp> rather than overwritten.
link_file() {
    local src="$1"
    local dst="$2"

    if [ ! -e "$src" ]; then
        print_warning "Source not found, skipping: $src"
        return 1
    fi

    mkdir -p "$(dirname "$dst")"

    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        print_status "Already linked: $dst"
        return 0
    fi

    if [ -e "$dst" ] || [ -L "$dst" ]; then
        local backup="$dst.bak.$(date +%Y%m%d%H%M%S)"
        mv "$dst" "$backup"
        print_warning "Existing $dst moved to $backup"
    fi

    ln -s "$src" "$dst"
    print_success "Linked $dst -> $src"
}
