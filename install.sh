#!/bin/bash
# ZChat Slim Installer v0.9
# Streamlined installer with minimal bloat

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[OK]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Global variables
VERBOSE=false
FORCE=false
OFFLINE=false
INSTALL_MODE="adaptive"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v) VERBOSE=true; shift ;;
        --force|-f) FORCE=true; shift ;;
        --offline|-o) OFFLINE=true; shift ;;
        --minimal) INSTALL_MODE="minimal"; shift ;;
        --standard) INSTALL_MODE="standard"; shift ;;
        --repair) INSTALL_MODE="repair"; shift ;;
        --onboarding) INSTALL_MODE="onboarding"; shift ;;
        --help|-h) 
            echo "ZChat Slim Installer v0.9"
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Modes: --minimal, --standard, --repair, --onboarding"
            echo "Options: --verbose, --force, --offline, --help"
            exit 0 
            ;;
        *) print_error "Unknown option: $1"; exit 1 ;;
    esac
done

# Simple progress bar
show_progress() {
    local current=$1 total=$2 desc="$3"
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    printf "\r[%s%s] %d%% %s" "$(printf "%*s" $filled | tr ' ' '#')" "$(printf "%*s" $empty | tr ' ' '-')" $percent "$desc"
    [ $current -eq $total ] && echo
}

# Detect environment
detect_env() {
    # OS detection
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS_TYPE="linux"
        if grep -qi microsoft /proc/version 2>/dev/null; then
            IS_WSL="true"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]]; then
        OS_TYPE="windows"
    else
        OS_TYPE="unknown"
    fi
    
    # Install prefix
    if [ "$EUID" -eq 0 ]; then
        INSTALL_PREFIX="/usr/local"
    else
        INSTALL_PREFIX="$HOME/.local"
    fi
    
    # Config directory
    if [ -n "${XDG_CONFIG_HOME:-}" ]; then
        CONFIG_DIR="$XDG_CONFIG_HOME/zchat"
    elif [ "$OS_TYPE" = "windows" ]; then
        CONFIG_DIR="${APPDATA:-$HOME/AppData/Roaming}/zchat"
    elif [ "$OS_TYPE" = "macos" ]; then
        CONFIG_DIR="$HOME/Library/Application Support/zchat"
    else
        CONFIG_DIR="$HOME/.config/zchat"
    fi
}

# Check existing installation
check_existing() {
    local found=false
    
    # Check binary
    if command -v z >/dev/null 2>&1; then
        local z_path=$(command -v z)
        if [ "$z_path" != "$(pwd)/z" ] && [ "$z_path" != "./z" ]; then
            found=true
        fi
    fi
    
    # Check config
    if [ -d "$CONFIG_DIR" ]; then
        found=true
    fi
    
    if [ "$found" = true ] && [ "$FORCE" != true ]; then
        print_warning "Existing installation detected. Use --force to overwrite."
        exit 0
    fi
}

# Detect clipboard environment
detect_clipboard_env() {
    if [ -n "${WAYLAND_DISPLAY:-}" ]; then
        CLIPBOARD_TOOL="wl-paste"
        CLIPBOARD_INSTALL="wl-clipboard"
    elif [ -n "${DISPLAY:-}" ]; then
        CLIPBOARD_TOOL="xclip"
        CLIPBOARD_INSTALL="xclip"
    elif [ -n "${WSL_DISTRO_NAME:-}" ] || [ -n "${WSLENV:-}" ]; then
        CLIPBOARD_TOOL="xclip"
        CLIPBOARD_INSTALL="xclip"
    elif [ "$OS_TYPE" = "macos" ]; then
        CLIPBOARD_TOOL="pbpaste"
        CLIPBOARD_INSTALL="builtin"
    elif [ "$OS_TYPE" = "windows" ]; then
        CLIPBOARD_TOOL="powershell"
        CLIPBOARD_INSTALL="builtin"
    else
        CLIPBOARD_TOOL="xclip"
        CLIPBOARD_INSTALL="xclip"
    fi
}

# Install system dependencies
install_system_deps() {
    print_info "Installing system dependencies..."
    
    detect_clipboard_env
    
    case "$OS_TYPE" in
        "linux")
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update -qq
                local packages="build-essential libssl-dev curl wget pkg-config libreadline-dev libncurses-dev zlib1g-dev"
                if [ "$CLIPBOARD_INSTALL" != "builtin" ]; then
                    packages="$packages $CLIPBOARD_INSTALL"
                fi
                sudo apt-get install -y -- $packages
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y gcc openssl-devel curl wget pkgconfig readline-devel ncurses-devel zlib-devel
                if [ "$CLIPBOARD_INSTALL" != "builtin" ]; then
                    sudo yum install -y -- $CLIPBOARD_INSTALL
                fi
            elif command -v pacman >/dev/null 2>&1; then
                sudo pacman -S --noconfirm base-devel openssl curl wget pkg-config readline ncurses zlib
                if [ "$CLIPBOARD_INSTALL" != "builtin" ]; then
                    sudo pacman -S --noconfirm -- $CLIPBOARD_INSTALL
                fi
            fi
            ;;
        "macos")
            if command -v brew >/dev/null 2>&1; then
                brew install openssl curl wget readline
            fi
            ;;
        "windows")
            if command -v choco >/dev/null 2>&1; then
                choco install -y curl wget
            elif command -v winget >/dev/null 2>&1; then
                winget install -e --id Microsoft.Curl
                winget install -e --id Microsoft.Wget
            fi
            ;;
    esac
    
    print_status "Clipboard tool: $CLIPBOARD_TOOL"
}

# Install Perl modules
install_perl_modules() {
    local modules=("Mojo::UserAgent" "JSON::XS" "YAML::XS" "Getopt::Long::Descriptive" "URI::Escape" "Data::Dumper" "String::ShellQuote" "File::Slurper" "File::Copy" "File::Temp" "File::Compare" "Carp" "Term::ReadLine" "Capture::Tiny" "LWP::UserAgent")
    
    print_info "Installing Perl modules..."
    
    # Install cpanm if needed
    if ! command -v cpanm >/dev/null 2>&1; then
        curl -L https://cpanmin.us | perl - App::cpanminus
    fi
    
    local total=${#modules[@]}
    local current=0
    
    for module in "${modules[@]}"; do
        current=$((current + 1))
        show_progress $current $total "Installing $module"
        
        if ! cpanm --notest --quiet "$module" 2>/dev/null; then
            print_warning "Failed to install $module"
        fi
    done
    echo
}

# Install ZChat
install_zchat() {
    print_info "Installing ZChat..."
    
    # Create directories
    mkdir -p "$INSTALL_PREFIX/bin"
    mkdir -p "$CONFIG_DIR/system"
    mkdir -p "$CONFIG_DIR/sessions"
    
    # Copy binary
    cp "./z" "$INSTALL_PREFIX/bin/z"
    chmod +x "$INSTALL_PREFIX/bin/z"
    
    # Create config
    if [ ! -f "$CONFIG_DIR/user.yaml" ]; then
        cat > "$CONFIG_DIR/user.yaml" << 'EOF'
session: "default"
system_string: "You are a helpful AI assistant."
api_key: ""
model: "gpt-4"
temperature: 0.7
max_tokens: 4000
EOF
    fi
    
    # Create system prompt
    cat > "$CONFIG_DIR/system/default" << 'EOF'
You are a helpful AI assistant. You provide clear, concise, and accurate responses.

You understand that this is a command-line interface, so you should:
- Be direct and practical in your responses
- Provide code examples when relevant
- Explain technical concepts clearly
- Focus on actionable advice
EOF
    
    # Create session
    mkdir -p "$CONFIG_DIR/sessions/default"
    cat > "$CONFIG_DIR/sessions/default/session.yaml" << 'EOF'
created: 1703123456
EOF
    
    print_status "ZChat installed to $INSTALL_PREFIX/bin/z"
}

# Configure shell
configure_shell() {
    local shell_config=""
    
    case "$SHELL" in
        *bash) shell_config="$HOME/.bashrc" ;;
        *zsh) shell_config="$HOME/.zshrc" ;;
        *fish) shell_config="$HOME/.config/fish/config.fish" ;;
        *) shell_config="$HOME/.profile" ;;
    esac
    
    if [ -n "$shell_config" ] && [ -f "$shell_config" ]; then
        if ! grep -q "$INSTALL_PREFIX/bin" "$shell_config"; then
            echo "export PATH=\"$INSTALL_PREFIX/bin:\$PATH\"" >> "$shell_config"
            print_status "Added to PATH in $shell_config"
        fi
    fi
}

# Run API onboarding
run_api_onboarding() {
    print_info "Running API onboarding..."
    
    if [ -f "./onboarding.pl" ]; then
        if perl -c "./onboarding.pl" 2>/dev/null; then
            echo ""
            echo "Would you like to run the interactive onboarding tutorial? (y/N)"
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                perl "./onboarding.pl"
            else
                print_info "Skipping onboarding. You can run it later with: perl onboarding.pl"
            fi
        else
            print_warning "Onboarding script has syntax errors, skipping"
        fi
    else
        print_warning "Onboarding script not found, skipping"
    fi
}

# Main installation
install_main() {
    print_info "Starting ZChat installation..."
    
    detect_env
    check_existing
    install_system_deps
    install_perl_modules
    install_zchat
    configure_shell
    run_api_onboarding
    
    print_status "Installation completed!"
    echo ""
    echo "Usage:"
    echo "  z --help                    # Show help"
    echo "  z \"Hello, world!\"          # Chat with AI"
    echo "  z --config                  # Configure API key"
    echo "  perl onboarding.pl          # Run interactive tutorial"
    echo ""
    echo "Note: You may need to restart your terminal for the 'z' command to be available."
}

# Repair installation
repair_main() {
    print_info "Repairing ZChat installation..."
    
    detect_env
    
    if [ -f "$INSTALL_PREFIX/bin/z" ]; then
        print_status "Binary found: $INSTALL_PREFIX/bin/z"
    else
        print_error "ZChat binary not found"
        exit 1
    fi
    
    if [ -d "$CONFIG_DIR" ]; then
        print_status "Config found: $CONFIG_DIR"
    else
        print_warning "Config directory not found, creating..."
        mkdir -p "$CONFIG_DIR/system" "$CONFIG_DIR/sessions"
    fi
    
    install_system_deps
    install_perl_modules
    
    print_status "Repair completed!"
}

# Onboarding only
onboarding_main() {
    print_info "Running ZChat onboarding tutorial..."
    
    if [ -f "./onboarding.pl" ]; then
        if perl -c "./onboarding.pl" 2>/dev/null; then
            perl "./onboarding.pl"
        else
            print_error "Onboarding script has syntax errors"
            exit 1
        fi
    else
        print_error "Onboarding script not found"
        exit 1
    fi
}

# Main execution
main() {
    echo -e "${BLUE}ZChat Slim Installer v0.9${NC}"
    echo ""
    
    case "$INSTALL_MODE" in
        "repair") repair_main ;;
        "onboarding") onboarding_main ;;
        *) install_main ;;
    esac
}

# Run main function
main "$@"