#!/bin/bash
# ZChat Comprehensive Installation Detector v0.9b
# Platform-agnostic detection of all possible installation forms

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

# Global variables for detected installations
declare -A INSTALLATION_PATHS
declare -A INSTALLATION_TYPES
INSTALLATION_COUNT=0

# Detect all possible installation locations
detect_all_installations() {
    print_info "Scanning for ZChat installations..."
    
    # Clear previous results
    INSTALLATION_PATHS=()
    INSTALLATION_TYPES=()
    INSTALLATION_COUNT=0
    
    # Detect platform-specific paths
    detect_platform_paths
    
    # Detect standard installations
    detect_standard_installations
    
    # Detect system-wide installations
    detect_system_installations
    
    # Detect bundle installations
    detect_bundle_installations
    
    # Detect single executable installations
    detect_single_executable_installations
    
    # Detect archive installations
    detect_archive_installations
    
    # Detect Perl library installations
    detect_perl_library_installations
    
    # Detect PATH-based installations
    detect_path_installations
    
    # Detect container installations
    detect_container_installations
    
    print_status "Found $INSTALLATION_COUNT installation(s)"
}

# Detect platform-specific installation paths
detect_platform_paths() {
    # User installations
    local user_paths=(
        "$HOME/.local/bin/z"
        "$HOME/.local/bin/zchat"
        "$HOME/bin/z"
        "$HOME/bin/zchat"
    )
    
    # System installations
    local system_paths=(
        "/usr/local/bin/z"
        "/usr/local/bin/zchat"
        "/usr/bin/z"
        "/usr/bin/zchat"
        "/opt/zchat/bin/z"
        "/opt/zchat/bin/zchat"
    )
    
    # macOS-specific paths
    if [ "${OS_TYPE:-}" = "macos" ]; then
        user_paths+=(
            "$HOME/.homebrew/bin/z"
            "$HOME/.homebrew/bin/zchat"
        )
        system_paths+=(
            "/opt/homebrew/bin/z"
            "/opt/homebrew/bin/zchat"
            "/usr/local/homebrew/bin/z"
            "/usr/local/homebrew/bin/zchat"
        )
    fi
    
    # Windows-specific paths
    if [ "${OS_TYPE:-}" = "windows" ]; then
        user_paths+=(
            "$HOME/AppData/Local/bin/z.exe"
            "$HOME/AppData/Local/bin/zchat.exe"
            "$HOME/.local/bin/z.exe"
            "$HOME/.local/bin/zchat.exe"
        )
        system_paths+=(
            "C:/Program Files/zchat/bin/z.exe"
            "C:/Program Files/zchat/bin/zchat.exe"
            "C:/Program Files (x86)/zchat/bin/z.exe"
            "C:/Program Files (x86)/zchat/bin/zchat.exe"
        )
    fi
    
    # Check user paths
    for path in "${user_paths[@]}"; do
        if [ -f "$path" ]; then
            add_installation "binary" "$path" "user"
        fi
    done
    
    # Check system paths
    for path in "${system_paths[@]}"; do
        if [ -f "$path" ]; then
            add_installation "binary" "$path" "system"
        fi
    done
}

# Detect standard installations (config + binary)
detect_standard_installations() {
    # Determine platform-sensitive config directory
    local config_dir
    if [ -n "${XDG_CONFIG_HOME:-}" ]; then
        config_dir="$XDG_CONFIG_HOME/zchat"
    elif [ "${OS_TYPE:-}" = "windows" ]; then
        config_dir="${APPDATA:-$HOME/AppData/Roaming}/zchat"
    elif [ "${OS_TYPE:-}" = "macos" ]; then
        config_dir="$HOME/Library/Application Support/zchat"
    else
        config_dir="$HOME/.config/zchat"
    fi
    
    # Check for config directory
    if [ -d "$config_dir" ]; then
        add_installation "config" "$config_dir" "standard"
        
        # Look for associated binary
        local possible_binaries=(
            "$HOME/.local/bin/z"
            "$HOME/.local/bin/zchat"
            "/usr/local/bin/z"
            "/usr/local/bin/zchat"
        )
        
        for binary in "${possible_binaries[@]}"; do
            if [ -f "$binary" ]; then
                add_installation "binary" "$binary" "standard"
                break
            fi
        done
    fi
}

# Detect system-wide installations
detect_system_installations() {
    # Check common system installation locations
    local system_locations=(
        "/usr/local/share/zchat"
        "/opt/zchat"
        "/usr/share/zchat"
        "/var/lib/zchat"
    )
    
    # macOS-specific system locations
    if [ "${OS_TYPE:-}" = "macos" ]; then
        system_locations+=(
            "/Applications/zchat"
            "/usr/local/Cellar/zchat"
        )
    fi
    
    # Windows-specific system locations
    if [ "${OS_TYPE:-}" = "windows" ]; then
        system_locations+=(
            "C:/Program Files/zchat"
            "C:/Program Files (x86)/zchat"
            "C:/ProgramData/zchat"
        )
    fi
    
    for location in "${system_locations[@]}"; do
        if [ -d "$location" ]; then
            add_installation "system" "$location" "system"
        fi
    done
}

# Detect bundle installations
detect_bundle_installations() {
    # Check current directory for bundles
    local bundle_patterns=(
        "zchat-static-bundle"
        "zchat-bundle-*"
        "zchat-bundle-optimized"
        "zchat-bundle-*-*"
    )
    
    for pattern in "${bundle_patterns[@]}"; do
        for bundle in $pattern; do
            if [ -d "$bundle" ]; then
                add_installation "bundle" "$bundle" "bundle"
            fi
        done
    done
    
    # Check common bundle installation locations
    local bundle_locations=(
        "$HOME/.local/share/zchat-bundles"
        "/opt/zchat-bundles"
        "/usr/local/share/zchat-bundles"
    )
    
    for location in "${bundle_locations[@]}"; do
        if [ -d "$location" ]; then
            add_installation "bundle" "$location" "bundle"
        fi
    done
}

# Detect single executable installations
detect_single_executable_installations() {
    # Check current directory for single executables
    local single_patterns=(
        "zchat-*-*-*"
        "zchat-single-*"
        "zchat-*.exe"
        "zchat-*.app"
    )
    
    for pattern in "${single_patterns[@]}"; do
        for single in $pattern; do
            if [ -f "$single" ] || [ -d "$single" ]; then
                add_installation "single" "$single" "single"
            fi
        done
    done
    
    # Check common single executable locations
    local single_locations=(
        "$HOME/.local/bin/zchat-*"
        "/usr/local/bin/zchat-*"
        "/opt/zchat-single"
    )
    
    for location in "${single_locations[@]}"; do
        if [ -f "$location" ] || [ -d "$location" ]; then
            add_installation "single" "$location" "single"
        fi
    done
}

# Detect archive installations
detect_archive_installations() {
    # Check current directory for archives
    local archive_patterns=(
        "zchat-*.tar.gz"
        "zchat-*.zip"
        "zchat-*.tar.bz2"
        "zchat-*.tar.xz"
    )
    
    for pattern in "${archive_patterns[@]}"; do
        for archive in $pattern; do
            if [ -f "$archive" ]; then
                add_installation "archive" "$archive" "archive"
            fi
        done
    done
    
    # Check common archive locations
    local archive_locations=(
        "$HOME/Downloads/zchat-*"
        "$HOME/.local/share/zchat-archives"
        "/tmp/zchat-*"
    )
    
    for location in "${archive_locations[@]}"; do
        if [ -f "$location" ]; then
            add_installation "archive" "$location" "archive"
        fi
    done
}

# Detect Perl library installations
detect_perl_library_installations() {
    # Check for Perl library installations
    local perl_lib_locations=(
        "$HOME/.local/bin/perl-lib"
        "$HOME/perl5"
        "$HOME/.perl5"
        "/usr/local/lib/perl5"
        "/opt/perl5"
    )
    
    for location in "${perl_lib_locations[@]}"; do
        if [ -d "$location" ]; then
            # Check if it contains ZChat-related modules
            if find "$location" -name "*ZChat*" -o -name "*zchat*" 2>/dev/null | grep -q .; then
                add_installation "perl-lib" "$location" "perl-lib"
            fi
        fi
    done
}

# Detect PATH-based installations
detect_path_installations() {
    # Check if z command is available in PATH
    if command -v z >/dev/null 2>&1; then
        local z_path=$(command -v z)
        
        # Skip if it's the source file
        if [ "$z_path" != "$(pwd)/z" ] && [ "$z_path" != "./z" ]; then
            add_installation "path" "$z_path" "path"
        fi
    fi
    
    # Check if zchat command is available in PATH
    if command -v zchat >/dev/null 2>&1; then
        local zchat_path=$(command -v zchat)
        add_installation "path" "$zchat_path" "path"
    fi
}

# Detect container installations
detect_container_installations() {
    # Check for container-specific installations
    if [ "${IS_CONTAINER:-}" = "true" ]; then
        local container_locations=(
            "/app/zchat"
            "/opt/app/zchat"
            "/usr/local/app/zchat"
        )
        
        for location in "${container_locations[@]}"; do
            if [ -d "$location" ]; then
                add_installation "container" "$location" "container"
            fi
        done
    fi
}

# Add installation to detected list
add_installation() {
    local type="$1"
    local path="$2"
    local category="$3"
    
    # Avoid duplicates
    for existing_path in "${INSTALLATION_PATHS[@]}"; do
        if [ "$existing_path" = "$path" ]; then
            return
        fi
    done
    
    INSTALLATION_PATHS["$INSTALLATION_COUNT"]="$path"
    INSTALLATION_TYPES["$INSTALLATION_COUNT"]="$type"
    INSTALLATION_CATEGORIES["$INSTALLATION_COUNT"]="$category"
    INSTALLATION_COUNT=$((INSTALLATION_COUNT + 1))
}

# Get installation summary
get_installation_summary() {
    if [ $INSTALLATION_COUNT -eq 0 ]; then
        echo "none"
        return
    fi
    
    local summary=""
    local categories=()
    
    # Collect unique categories
    for i in $(seq 0 $((INSTALLATION_COUNT - 1))); do
        local category="${INSTALLATION_CATEGORIES[$i]}"
        if [[ ! " ${categories[@]} " =~ " ${category} " ]]; then
            categories+=("$category")
        fi
    done
    
    # Create summary
    if [ ${#categories[@]} -eq 1 ]; then
        summary="${categories[0]}"
    else
        summary="multiple (${categories[*]})"
    fi
    
    echo "$summary"
}

# Generate installation report
generate_installation_report() {
    if [ $INSTALLATION_COUNT -eq 0 ]; then
        print_warning "No ZChat installations detected"
        return
    fi
    
    echo ""
    echo "=== ZChat Installation Report ==="
    echo ""
    
    for i in $(seq 0 $((INSTALLATION_COUNT - 1))); do
        local path="${INSTALLATION_PATHS[$i]}"
        local type="${INSTALLATION_TYPES[$i]}"
        local category="${INSTALLATION_CATEGORIES[$i]}"
        
        echo "Installation $((i + 1)):"
        echo "  Type: $type"
        echo "  Category: $category"
        echo "  Path: $path"
        
        # Show additional details
        if [ -f "$path" ]; then
            echo "  Size: $(ls -lh "$path" | awk '{print $5}')"
            echo "  Modified: $(ls -l "$path" | awk '{print $6, $7, $8}')"
        elif [ -d "$path" ]; then
            echo "  Contents: $(ls "$path" | wc -l) items"
        fi
        echo ""
    done
    
    echo "Summary: $(get_installation_summary)"
    echo ""
}

# Export installation information
export_installation_info() {
    export INSTALLATION_COUNT
    export INSTALLATION_PATHS
    export INSTALLATION_TYPES
    export INSTALLATION_CATEGORIES
}

# If script is run directly, perform installation detection
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    # Source environment detector first
    if [ -f "./install/environment-detector.sh" ]; then
        source ./install/environment-detector.sh
        detect_environment
    fi
    
    detect_all_installations
    generate_installation_report
    export_installation_info
fi