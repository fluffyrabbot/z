#!/bin/bash
# ZChat Advanced Dependency Detector v0.9b
# Detects and handles complex dependency scenarios

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

# Advanced dependency detection
detect_advanced_dependencies() {
    print_info "Running advanced dependency detection..."
    
    # Detect Perl module dependencies
    detect_perl_module_dependencies
    
    # Detect system library dependencies
    detect_system_library_dependencies
    
    # Detect build tool dependencies
    detect_build_tool_dependencies
    
    # Detect platform-specific dependencies
    detect_platform_specific_dependencies
    
    # Generate dependency report
    generate_dependency_report
}

# Detect Perl module dependencies
detect_perl_module_dependencies() {
    print_info "Detecting Perl module dependencies..."
    
    # Core modules
    local core_modules=("Mojo::UserAgent" "JSON::XS" "YAML::XS" "Getopt::Long::Descriptive" "URI::Escape" "Data::Dumper" "String::ShellQuote" "File::Slurper" "File::Copy" "File::Temp" "File::Compare" "Carp" "Term::ReadLine" "Capture::Tiny" "LWP::UserAgent")
    
    # Optional modules
    local optional_modules=("Image::Magick" "Text::Xslate" "Term::ReadLine::Gnu" "Term::Size")
    
    # Check core modules
    local missing_core=()
    local available_core=()
    
    for module in "${core_modules[@]}"; do
        if perl -e "use $module; 1" 2>/dev/null; then
            available_core+=("$module")
        else
            missing_core+=("$module")
        fi
    done
    
    # Check optional modules
    local missing_optional=()
    local available_optional=()
    
    for module in "${optional_modules[@]}"; do
        if perl -e "use $module; 1" 2>/dev/null; then
            available_optional+=("$module")
        else
            missing_optional+=("$module")
        fi
    done
    
    # Store results
    AVAILABLE_CORE_MODULES=("${available_core[@]}")
    MISSING_CORE_MODULES=("${missing_core[@]}")
    AVAILABLE_OPTIONAL_MODULES=("${available_optional[@]}")
    MISSING_OPTIONAL_MODULES=("${missing_optional[@]}")
    
    print_status "Core modules: ${#available_core[@]}/${#core_modules[@]} available"
    print_status "Optional modules: ${#available_optional[@]}/${#optional_modules[@]} available"
}

# Detect system library dependencies
detect_system_library_dependencies() {
    print_info "Detecting system library dependencies..."
    
    local missing_libs=()
    local available_libs=()
    
    # Check for common system libraries
    local libs=("ssl" "crypto" "z" "readline" "ncurses")
    
    for lib in "${libs[@]}"; do
        if ldconfig -p 2>/dev/null | grep -q "lib$lib"; then
            available_libs+=("lib$lib")
        else
            missing_libs+=("lib$lib")
        fi
    done
    
    # Check for development headers
    local missing_headers=()
    local available_headers=()
    
    local headers=("stdio.h" "stdlib.h" "openssl/ssl.h" "readline/readline.h" "ncurses.h")
    
    for header in "${headers[@]}"; do
        if [ -f "/usr/include/$header" ] || [ -f "/usr/local/include/$header" ]; then
            available_headers+=("$header")
        else
            missing_headers+=("$header")
        fi
    done
    
    # Store results
    AVAILABLE_LIBS=("${available_libs[@]}")
    MISSING_LIBS=("${missing_libs[@]}")
    AVAILABLE_HEADERS=("${available_headers[@]}")
    MISSING_HEADERS=("${missing_headers[@]}")
    
    print_status "System libraries: ${#available_libs[@]}/${#libs[@]} available"
    print_status "Development headers: ${#available_headers[@]}/${#headers[@]} available"
}

# Detect build tool dependencies
detect_build_tool_dependencies() {
    print_info "Detecting build tool dependencies..."
    
    local missing_tools=()
    local available_tools=()
    
    # Check for build tools
    local tools=("gcc" "make" "pkg-config" "cpanm")
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            available_tools+=("$tool")
            # Get version if possible
            case "$tool" in
                "gcc")
                    GCC_VERSION=$(gcc --version | head -1 | sed 's/.*gcc \([0-9.]*\).*/\1/')
                    ;;
                "make")
                    MAKE_VERSION=$(make --version | head -1 | sed 's/.*Make \([0-9.]*\).*/\1/')
                    ;;
                "pkg-config")
                    PKG_CONFIG_VERSION=$(pkg-config --version)
                    ;;
                "cpanm")
                    CPANM_VERSION=$(cpanm --version 2>/dev/null | head -1 || echo "unknown")
                    ;;
            esac
        else
            missing_tools+=("$tool")
        fi
    done
    
    # Store results
    AVAILABLE_TOOLS=("${available_tools[@]}")
    MISSING_TOOLS=("${missing_tools[@]}")
    
    print_status "Build tools: ${#available_tools[@]}/${#tools[@]} available"
}

# Detect platform-specific dependencies
detect_platform_specific_dependencies() {
    print_info "Detecting platform-specific dependencies..."
    
    # Detect clipboard tools
    local clipboard_tools=("xclip" "xsel" "wl-paste" "pbpaste" "powershell")
    local available_clipboard=()
    
    for tool in "${clipboard_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            available_clipboard+=("$tool")
        fi
    done
    
    # Detect terminal capabilities
    local terminal_caps=()
    
    if [ -n "$COLORTERM" ]; then
        terminal_caps+=("color")
    fi
    
    if command -v tput >/dev/null 2>&1; then
        terminal_caps+=("size")
    fi
    
    if [ -n "$TERM_PROGRAM" ]; then
        terminal_caps+=("program")
    fi
    
    # Store results
    AVAILABLE_CLIPBOARD_TOOLS=("${available_clipboard[@]}")
    TERMINAL_CAPABILITIES=("${terminal_caps[@]}")
    
    print_status "Clipboard tools: ${#available_clipboard[@]}/${#clipboard_tools[@]} available"
    print_status "Terminal capabilities: ${terminal_caps[*]}"
}

# Generate dependency report
generate_dependency_report() {
    print_info "Generating dependency report..."
    
    echo ""
    echo "=== ZChat Dependency Report ==="
    echo ""
    
    # Core modules report
    echo "Core Perl Modules:"
    if [ ${#MISSING_CORE_MODULES[@]} -eq 0 ]; then
        echo "  ✓ All core modules available"
    else
        echo "  ✗ Missing core modules: ${MISSING_CORE_MODULES[*]}"
    fi
    
    # Optional modules report
    echo "Optional Perl Modules:"
    if [ ${#AVAILABLE_OPTIONAL_MODULES[@]} -gt 0 ]; then
        echo "  ✓ Available: ${AVAILABLE_OPTIONAL_MODULES[*]}"
    fi
    if [ ${#MISSING_OPTIONAL_MODULES[@]} -gt 0 ]; then
        echo "  ⚠ Missing: ${MISSING_OPTIONAL_MODULES[*]} (non-fatal)"
    fi
    
    # System libraries report
    echo "System Libraries:"
    if [ ${#MISSING_LIBS[@]} -eq 0 ]; then
        echo "  ✓ All required libraries available"
    else
        echo "  ✗ Missing libraries: ${MISSING_LIBS[*]}"
    fi
    
    # Development headers report
    echo "Development Headers:"
    if [ ${#MISSING_HEADERS[@]} -eq 0 ]; then
        echo "  ✓ All required headers available"
    else
        echo "  ✗ Missing headers: ${MISSING_HEADERS[*]}"
    fi
    
    # Build tools report
    echo "Build Tools:"
    if [ ${#MISSING_TOOLS[@]} -eq 0 ]; then
        echo "  ✓ All build tools available"
    else
        echo "  ✗ Missing tools: ${MISSING_TOOLS[*]}"
    fi
    
    # Platform-specific report
    echo "Platform-Specific Tools:"
    if [ ${#AVAILABLE_CLIPBOARD_TOOLS[@]} -gt 0 ]; then
        echo "  ✓ Clipboard tools: ${AVAILABLE_CLIPBOARD_TOOLS[*]}"
    else
        echo "  ⚠ No clipboard tools available"
    fi
    
    if [ ${#TERMINAL_CAPABILITIES[@]} -gt 0 ]; then
        echo "  ✓ Terminal capabilities: ${TERMINAL_CAPABILITIES[*]}"
    else
        echo "  ⚠ Limited terminal capabilities"
    fi
    
    echo ""
    
    # Recommendations
    echo "Recommendations:"
    if [ ${#MISSING_CORE_MODULES[@]} -gt 0 ]; then
        echo "  • Install missing core modules: cpanm ${MISSING_CORE_MODULES[*]}"
    fi
    
    if [ ${#MISSING_LIBS[@]} -gt 0 ]; then
        echo "  • Install missing system libraries"
        case "$PACKAGE_MANAGER" in
            "apt")
                echo "    sudo apt-get install libssl-dev libreadline-dev libncurses-dev zlib1g-dev"
                ;;
            "yum")
                echo "    sudo yum install openssl-devel readline-devel ncurses-devel zlib-devel"
                ;;
            "pacman")
                echo "    sudo pacman -S openssl readline ncurses zlib"
                ;;
        esac
    fi
    
    if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
        echo "  • Install missing build tools"
        case "$PACKAGE_MANAGER" in
            "apt")
                echo "    sudo apt-get install build-essential pkg-config"
                ;;
            "yum")
                echo "    sudo yum install gcc make pkgconfig"
                ;;
            "pacman")
                echo "    sudo pacman -S base-devel pkg-config"
                ;;
        esac
    fi
    
    if [ ${#AVAILABLE_CLIPBOARD_TOOLS[@]} -eq 0 ]; then
        echo "  • Install clipboard tools for --clipboard functionality"
        case "$PACKAGE_MANAGER" in
            "apt")
                echo "    sudo apt-get install xclip"
                ;;
            "yum")
                echo "    sudo yum install xclip"
                ;;
            "pacman")
                echo "    sudo pacman -S xclip"
                ;;
        esac
    fi
    
    echo ""
}

# Export dependency information
export_dependency_info() {
    export AVAILABLE_CORE_MODULES MISSING_CORE_MODULES
    export AVAILABLE_OPTIONAL_MODULES MISSING_OPTIONAL_MODULES
    export AVAILABLE_LIBS MISSING_LIBS
    export AVAILABLE_HEADERS MISSING_HEADERS
    export AVAILABLE_TOOLS MISSING_TOOLS
    export AVAILABLE_CLIPBOARD_TOOLS TERMINAL_CAPABILITIES
}

# If script is run directly, perform dependency detection
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    # Source environment detector first
    if [ -f "./install/environment-detector.sh" ]; then
        source ./install/environment-detector.sh
        detect_environment
    fi
    
    detect_advanced_dependencies
    export_dependency_info
fi