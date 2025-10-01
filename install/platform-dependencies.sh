#!/bin/bash
# ZChat Platform-Specific Dependencies v0.9b
# Handles platform and environment-specific dependency detection and installation

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
LIGHT_BLUE='\033[0;36m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[OK]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Platform-specific dependency detection and installation
install_platform_dependencies() {
    print_info "Installing platform-specific dependencies..."
    
    # Detect environment
    detect_clipboard_environment
    detect_terminal_environment
    detect_build_environment
    detect_system_libraries
    
    # Install based on environment
    install_clipboard_tools
    install_terminal_tools
    install_build_tools
    install_system_libraries
    
    print_status "Platform dependencies installation completed!"
}

# Detect clipboard environment
detect_clipboard_environment() {
    print_info "Detecting clipboard environment..."
    
    # Detect display server
    if [ -n "$WAYLAND_DISPLAY" ]; then
        CLIPBOARD_ENV="wayland"
        print_info "Wayland display server detected"
    elif [ -n "$DISPLAY" ]; then
        CLIPBOARD_ENV="x11"
        print_info "X11 display server detected"
    elif [ "$IS_WSL" = "true" ]; then
        CLIPBOARD_ENV="wsl"
        print_info "WSL environment detected"
    else
        CLIPBOARD_ENV="headless"
        print_warning "No display server detected (headless environment)"
    fi
    
    # Detect available clipboard tools
    CLIPBOARD_TOOLS=()
    if command -v xclip >/dev/null 2>&1; then
        CLIPBOARD_TOOLS+=("xclip")
    fi
    if command -v xsel >/dev/null 2>&1; then
        CLIPBOARD_TOOLS+=("xsel")
    fi
    if command -v wl-paste >/dev/null 2>&1; then
        CLIPBOARD_TOOLS+=("wl-paste")
    fi
    if command -v pbpaste >/dev/null 2>&1; then
        CLIPBOARD_TOOLS+=("pbpaste")
    fi
    if command -v powershell >/dev/null 2>&1; then
        CLIPBOARD_TOOLS+=("powershell")
    fi
    
    print_status "Clipboard environment: $CLIPBOARD_ENV"
    print_status "Available tools: ${CLIPBOARD_TOOLS[*]}"
}

# Detect terminal environment
detect_terminal_environment() {
    print_info "Detecting terminal environment..."
    
    # Detect terminal emulator
    if [ -n "$TERM_PROGRAM" ]; then
        TERMINAL_EMULATOR="$TERM_PROGRAM"
    elif [ -n "$TERMINAL_EMULATOR" ]; then
        TERMINAL_EMULATOR="$TERMINAL_EMULATOR"
    else
        TERMINAL_EMULATOR="unknown"
    fi
    
    # Detect color support
    if [ -n "$COLORTERM" ]; then
        COLOR_SUPPORT="true"
    elif [ "$TERM" = "xterm-256color" ] || [ "$TERM" = "screen-256color" ]; then
        COLOR_SUPPORT="true"
    else
        COLOR_SUPPORT="false"
    fi
    
    # Detect terminal size
    if command -v tput >/dev/null 2>&1; then
        TERMINAL_COLUMNS=$(tput cols 2>/dev/null || echo "80")
        TERMINAL_LINES=$(tput lines 2>/dev/null || echo "24")
    else
        TERMINAL_COLUMNS="80"
        TERMINAL_LINES="24"
    fi
    
    print_status "Terminal: $TERMINAL_EMULATOR"
    print_status "Color support: $COLOR_SUPPORT"
    print_status "Size: ${TERMINAL_COLUMNS}x${TERMINAL_LINES}"
}

# Detect build environment
detect_build_environment() {
    print_info "Detecting build environment..."
    
    # Detect compiler
    if command -v gcc >/dev/null 2>&1; then
        GCC_VERSION=$(gcc --version | head -1 | sed 's/.*gcc \([0-9.]*\).*/\1/')
        print_status "GCC $GCC_VERSION detected"
    else
        print_warning "GCC not found"
    fi
    
    # Detect make
    if command -v make >/dev/null 2>&1; then
        MAKE_VERSION=$(make --version | head -1 | sed 's/.*Make \([0-9.]*\).*/\1/')
        print_status "Make $MAKE_VERSION detected"
    else
        print_warning "Make not found"
    fi
    
    # Detect pkg-config
    if command -v pkg-config >/dev/null 2>&1; then
        print_status "pkg-config available"
    else
        print_warning "pkg-config not found"
    fi
    
    # Detect development headers
    check_development_headers
}

# Check development headers
check_development_headers() {
    print_info "Checking development headers..."
    
    local missing_headers=()
    
    # Check common development headers
    if [ ! -f "/usr/include/stdio.h" ] && [ ! -f "/usr/local/include/stdio.h" ]; then
        missing_headers+=("stdio.h")
    fi
    if [ ! -f "/usr/include/stdlib.h" ] && [ ! -f "/usr/local/include/stdlib.h" ]; then
        missing_headers+=("stdlib.h")
    fi
    if [ ! -f "/usr/include/openssl/ssl.h" ] && [ ! -f "/usr/local/include/openssl/ssl.h" ]; then
        missing_headers+=("openssl/ssl.h")
    fi
    
    if [ ${#missing_headers[@]} -gt 0 ]; then
        print_warning "Missing development headers: ${missing_headers[*]}"
        MISSING_HEADERS=("${missing_headers[@]}")
    else
        print_status "Development headers available"
        MISSING_HEADERS=()
    fi
}

# Detect system libraries
detect_system_libraries() {
    print_info "Detecting system libraries..."
    
    # Check for common system libraries
    local missing_libs=()
    
    # Check for libssl
    if ! ldconfig -p 2>/dev/null | grep -q libssl; then
        missing_libs+=("libssl")
    fi
    
    # Check for libcrypto
    if ! ldconfig -p 2>/dev/null | grep -q libcrypto; then
        missing_libs+=("libcrypto")
    fi
    
    # Check for zlib
    if ! ldconfig -p 2>/dev/null | grep -q libz; then
        missing_libs+=("libz")
    fi
    
    if [ ${#missing_libs[@]} -gt 0 ]; then
        print_warning "Missing system libraries: ${missing_libs[*]}"
        MISSING_LIBS=("${missing_libs[@]}")
    else
        print_status "System libraries available"
        MISSING_LIBS=()
    fi
}

# Install clipboard tools
install_clipboard_tools() {
    print_info "Installing clipboard tools for $CLIPBOARD_ENV environment..."
    
    case "$CLIPBOARD_ENV" in
        "x11"|"wsl")
            if [ ! -f "/usr/bin/xclip" ]; then
                print_info "Installing xclip for X11/WSL clipboard support..."
                if [ "$PACKAGE_MANAGER" = "apt" ]; then
                    sudo apt-get install -y xclip
                elif [ "$PACKAGE_MANAGER" = "yum" ]; then
                    sudo yum install -y xclip
                elif [ "$PACKAGE_MANAGER" = "pacman" ]; then
                    sudo pacman -S --noconfirm xclip
                elif [ "$PACKAGE_MANAGER" = "brew" ]; then
                    brew install xclip
                else
                    print_warning "Cannot install xclip automatically on this system"
                fi
            else
                print_status "xclip already installed"
            fi
            ;;
        "wayland")
            if [ ! -f "/usr/bin/wl-paste" ]; then
                print_info "Installing wl-clipboard for Wayland clipboard support..."
                if [ "$PACKAGE_MANAGER" = "apt" ]; then
                    sudo apt-get install -y wl-clipboard
                elif [ "$PACKAGE_MANAGER" = "yum" ]; then
                    sudo yum install -y wl-clipboard
                elif [ "$PACKAGE_MANAGER" = "pacman" ]; then
                    sudo pacman -S --noconfirm wl-clipboard
                else
                    print_warning "Cannot install wl-clipboard automatically on this system"
                fi
            else
                print_status "wl-clipboard already installed"
            fi
            ;;
        "headless")
            print_warning "Headless environment detected - clipboard functionality will be limited"
            ;;
    esac
}

# Install terminal tools
install_terminal_tools() {
    print_info "Installing terminal tools..."
    
    # Install readline development libraries if needed
    if [ "$PACKAGE_MANAGER" = "apt" ]; then
        if ! dpkg -l | grep -q libreadline-dev; then
            print_info "Installing readline development libraries..."
            sudo apt-get install -y libreadline-dev
        fi
    elif [ "$PACKAGE_MANAGER" = "yum" ]; then
        if ! rpm -q readline-devel >/dev/null 2>&1; then
            print_info "Installing readline development libraries..."
            sudo yum install -y readline-devel
        fi
    elif [ "$PACKAGE_MANAGER" = "pacman" ]; then
        if ! pacman -Q readline >/dev/null 2>&1; then
            print_info "Installing readline development libraries..."
            sudo pacman -S --noconfirm readline
        fi
    fi
}

# Install build tools
install_build_tools() {
    print_info "Installing build tools..."
    
    if [ ${#MISSING_HEADERS[@]} -gt 0 ]; then
        print_info "Installing missing development headers..."
        
        case "$PACKAGE_MANAGER" in
            "apt")
                sudo apt-get install -y build-essential libssl-dev
                ;;
            "yum")
                sudo yum install -y gcc openssl-devel
                ;;
            "pacman")
                sudo pacman -S --noconfirm base-devel openssl
                ;;
            "brew")
                brew install openssl
                ;;
        esac
    fi
}

# Install system libraries
install_system_libraries() {
    print_info "Installing system libraries..."
    
    if [ ${#MISSING_LIBS[@]} -gt 0 ]; then
        print_info "Installing missing system libraries..."
        
        case "$PACKAGE_MANAGER" in
            "apt")
                sudo apt-get install -y libssl-dev zlib1g-dev
                ;;
            "yum")
                sudo yum install -y openssl-devel zlib-devel
                ;;
            "pacman")
                sudo pacman -S --noconfirm openssl zlib
                ;;
            "brew")
                brew install openssl zlib
                ;;
        esac
    fi
}

# Export environment variables
export_platform_environment() {
    export CLIPBOARD_ENV CLIPBOARD_TOOLS
    export TERMINAL_EMULATOR COLOR_SUPPORT TERMINAL_COLUMNS TERMINAL_LINES
    export MISSING_HEADERS MISSING_LIBS
}

# If script is run directly, perform platform dependency installation
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    # Source environment detector first
    if [ -f "./install/environment-detector.sh" ]; then
        source ./install/environment-detector.sh
        detect_environment
    fi
    
    install_platform_dependencies
    export_platform_environment
fi