#!/bin/bash
# ZChat Environment Detector v0.8b

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

# Global environment variables
export OS_TYPE=""
export DISTRO=""
export DISTRO_VERSION=""
export PACKAGE_MANAGER=""
export PERL_VERSION=""
export PERL_ARCH=""
export HAS_SUDO=""
export HAS_CURL=""
export HAS_WGET=""
export IS_WSL=""
export IS_CONTAINER=""
export IS_ROOT=""
export USER_HOME=""
export INSTALL_PREFIX=""

# Detect operating system
detect_os() {
    print_info "Detecting operating system..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS_TYPE="linux"
        detect_linux_distro
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
        DISTRO="macos"
        PACKAGE_MANAGER="brew"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        OS_TYPE="windows"
        DISTRO="windows"
        PACKAGE_MANAGER="chocolatey"
    elif [[ "$OSTYPE" == "freebsd"* ]]; then
        OS_TYPE="freebsd"
        DISTRO="freebsd"
        PACKAGE_MANAGER="pkg"
    else
        OS_TYPE="unknown"
        DISTRO="unknown"
        print_warning "Unknown operating system: $OSTYPE"
    fi
    
    print_status "OS: $OS_TYPE, Distro: $DISTRO"
}

# Detect Linux distribution
detect_linux_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO="$ID"
        DISTRO_VERSION="$VERSION_ID"
        
        # Map to package managers
        case "$ID" in
            "ubuntu"|"debian")
                PACKAGE_MANAGER="apt"
                ;;
            "centos"|"rhel"|"fedora")
                PACKAGE_MANAGER="yum"
                ;;
            "arch"|"manjaro")
                PACKAGE_MANAGER="pacman"
                ;;
            "opensuse"|"sles")
                PACKAGE_MANAGER="zypper"
                ;;
            "alpine")
                PACKAGE_MANAGER="apk"
                ;;
            *)
                PACKAGE_MANAGER="unknown"
                print_warning "Unknown Linux distribution: $ID"
                ;;
        esac
    elif [ -f /etc/redhat-release ]; then
        DISTRO="redhat"
        PACKAGE_MANAGER="yum"
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
        PACKAGE_MANAGER="apt"
    else
        DISTRO="unknown"
        PACKAGE_MANAGER="unknown"
        print_warning "Could not detect Linux distribution"
    fi
}

# Detect WSL
detect_wsl() {
    if [ -f /proc/version ] && grep -qi microsoft /proc/version; then
        IS_WSL="true"
        print_info "WSL (Windows Subsystem for Linux) detected"
    else
        IS_WSL="false"
    fi
}

# Detect container environment
detect_container() {
    if [ -f /.dockerenv ] || [ -n "${KUBERNETES_SERVICE_HOST:-}" ] || [ -n "${CONTAINER:-}" ]; then
        IS_CONTAINER="true"
        print_info "Container environment detected"
    else
        IS_CONTAINER="false"
    fi
}

# Detect Perl version and architecture
detect_perl() {
    print_info "Detecting Perl installation..."
    
    if command -v perl >/dev/null 2>&1; then
        PERL_VERSION=$(perl -v | head -2 | tail -1 | sed 's/.*v\([0-9.]*\).*/\1/')
        PERL_ARCH=$(perl -MConfig -e 'print $Config{archname}')
        print_status "Perl $PERL_VERSION ($PERL_ARCH)"
        
        # Check if version meets requirements
        if perl -e 'use v5.26.3; 1' 2>/dev/null; then
            print_status "Perl version meets ZChat requirements"
        else
            print_error "Perl version too old. ZChat requires Perl 5.26.3 or later"
            return 1
        fi
    else
        print_error "Perl not found"
        return 1
    fi
}

# Detect available tools
detect_tools() {
    print_info "Detecting available tools..."
    
    # Check sudo
    if command -v sudo >/dev/null 2>&1; then
        HAS_SUDO="true"
        print_status "sudo available"
    else
        HAS_SUDO="false"
        print_warning "sudo not available"
    fi
    
    # Check curl
    if command -v curl >/dev/null 2>&1; then
        HAS_CURL="true"
        print_status "curl available"
    else
        HAS_CURL="false"
        print_warning "curl not available"
    fi
    
    # Check wget
    if command -v wget >/dev/null 2>&1; then
        HAS_WGET="true"
        print_status "wget available"
    else
        HAS_WGET="false"
        print_warning "wget not available"
    fi
}

# Detect user environment
detect_user_env() {
    print_info "Detecting user environment..."
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        IS_ROOT="true"
        print_warning "Running as root"
    else
        IS_ROOT="false"
        print_status "Running as regular user"
    fi
    
    # Get user home directory
    USER_HOME="$HOME"
    print_status "User home: $USER_HOME"
    
    # Determine install prefix
    if [ "$IS_ROOT" = "true" ]; then
        INSTALL_PREFIX="/usr/local"
    else
        INSTALL_PREFIX="$USER_HOME/.local"
    fi
    print_status "Install prefix: $INSTALL_PREFIX"
}

# Get package manager commands
get_package_commands() {
    case "$PACKAGE_MANAGER" in
        "apt")
            UPDATE_CMD="sudo apt-get update -qq"
            INSTALL_CMD="sudo apt-get install -y"
            BUILD_PACKAGES="build-essential libssl-dev curl wget"
            IMAGEMAGICK_PACKAGES="libmagickwand-dev imagemagick"
            ;;
        "yum")
            UPDATE_CMD="sudo yum update -y"
            INSTALL_CMD="sudo yum install -y"
            BUILD_PACKAGES="gcc openssl-devel curl wget"
            IMAGEMAGICK_PACKAGES="ImageMagick-devel ImageMagick"
            ;;
        "pacman")
            UPDATE_CMD="sudo pacman -Sy"
            INSTALL_CMD="sudo pacman -S --noconfirm"
            BUILD_PACKAGES="base-devel curl wget"
            IMAGEMAGICK_PACKAGES="imagemagick"
            ;;
        "zypper")
            UPDATE_CMD="sudo zypper refresh"
            INSTALL_CMD="sudo zypper install -y"
            BUILD_PACKAGES="gcc libopenssl-devel curl wget"
            IMAGEMAGICK_PACKAGES="ImageMagick-devel ImageMagick"
            ;;
        "apk")
            UPDATE_CMD="sudo apk update"
            INSTALL_CMD="sudo apk add"
            BUILD_PACKAGES="build-base openssl-dev curl wget"
            IMAGEMAGICK_PACKAGES="imagemagick-dev imagemagick"
            ;;
        "brew")
            UPDATE_CMD="brew update"
            INSTALL_CMD="brew install"
            BUILD_PACKAGES="curl wget"
            IMAGEMAGICK_PACKAGES="imagemagick"
            ;;
        *)
            print_warning "Unknown package manager: $PACKAGE_MANAGER"
            UPDATE_CMD=""
            INSTALL_CMD=""
            BUILD_PACKAGES=""
            IMAGEMAGICK_PACKAGES=""
            ;;
    esac
}

# Export environment variables
export_environment() {
    export OS_TYPE DISTRO DISTRO_VERSION PACKAGE_MANAGER
    export PERL_VERSION PERL_ARCH HAS_SUDO HAS_CURL HAS_WGET
    export IS_WSL IS_CONTAINER IS_ROOT USER_HOME INSTALL_PREFIX
    export UPDATE_CMD INSTALL_CMD BUILD_PACKAGES IMAGEMAGICK_PACKAGES
}

# Main detection function
detect_environment() {
    echo "ZChat Environment Detector v0.8b"
    echo "================================="
    echo ""
    
    detect_os
    detect_wsl
    detect_container
    detect_perl || exit 1
    detect_tools
    detect_user_env
    get_package_commands
    export_environment
    
    echo ""
    print_status "Environment detection completed!"
    echo ""
    echo "Environment Summary:"
    echo "  OS: $OS_TYPE ($DISTRO $DISTRO_VERSION)"
    echo "  Package Manager: $PACKAGE_MANAGER"
    echo "  Perl: $PERL_VERSION ($PERL_ARCH)"
    echo "  User: $([ "$IS_ROOT" = "true" ] && echo "root" || echo "regular")"
    echo "  Install Prefix: $INSTALL_PREFIX"
    echo "  WSL: $IS_WSL"
    echo "  Container: $IS_CONTAINER"
    echo ""
    
    # Recommendations
    echo "Recommendations:"
    if [ "$IS_WSL" = "true" ]; then
        echo "  - WSL detected: Consider using Windows-native Perl for better performance"
    fi
    
    if [ "$IS_CONTAINER" = "true" ]; then
        echo "  - Container detected: Use static bundle for maximum portability"
    fi
    
    if [ "$IS_ROOT" = "true" ]; then
        echo "  - Running as root: Consider using user installation for security"
    fi
    
    if [ "$PACKAGE_MANAGER" = "unknown" ]; then
        echo "  - Unknown package manager: Manual installation may be required"
    fi
}

# If script is run directly, perform detection
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    detect_environment
fi