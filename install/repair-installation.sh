#!/bin/bash
# ZChat Installation Repair Script v0.9b
# Enhanced repair with progress bars, retry logic, and comprehensive uninstaller
# 
# Uninstaller Features:
# - Comprehensive detection of all installation modes (standard, bundle, single, platform, optimized)
# - Progress bars for all cleanup operations
# - Safe removal of bundle directories, single executables, and archive files
# - Intelligent Perl library cleanup with user confirmation
# - PATH entry detection and cleanup guidance
# - Mixed installation type support

# Enable set -e but handle errors gracefully
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    set -e
fi

# Source progress utilities
if [ -f "./progress-utils.sh" ]; then
    source ./progress-utils.sh
elif [ -f "./install/progress-utils.sh" ]; then
    source ./install/progress-utils.sh
else
    echo "Warning: progress-utils.sh not found, using basic progress"
    # Fallback colors and functions
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    LIGHT_BLUE='\033[0;36m'
    NC='\033[0m'
    
    show_progress_bar() {
        local current=$1
        local total=$2
        local desc=$3
        local percent=$((current * 100 / total))
        local filled=$((percent / 2))
        local empty=$((50 - filled))
        printf "\r[%3d%%] [" $percent
        printf "%*s" $filled | tr ' ' '#'
        printf "%*s" $empty | tr ' ' '-'
        printf "] %s (%d/%d)" "$desc" $current $total
    }
    
    show_enhanced_progress() {
        local current=$1
        local total=$2
        local desc=$3
        local status=$4
        
        case $status in
            "success")
                printf "\r✓ %s\n" "$desc"
                ;;
            "failed")
                printf "\r✗ %s\n" "$desc"
                ;;
            *)
                show_progress_bar $current $total "$desc"
                ;;
        esac
    }
    
    retry_operation() {
        local max_attempts=$1
        local delay=$2
        local operation="$3"
        local desc="$4"
        
        local attempt=1
        while [ $attempt -le $max_attempts ]; do
            if eval "$operation"; then
                echo -e "${GREEN}✓ Success: $desc${NC}"
                return 0
            else
                echo -e "${RED}✗ Failed attempt $attempt: $desc${NC}"
                ((attempt++))
                sleep $delay
            fi
        done
        return 1
    }
fi

print_status() { echo -e "${GREEN}[OK]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Parse command line arguments (only when executed directly)
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    VERBOSE=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
else
    # When sourced, set default values
    VERBOSE=false
fi

# Main execution logic
main() {
    # Setup logging
    setup_logging

    echo "ZChat Installation Repair Tool"
    echo "==============================="
    echo ""
    echo "This tool can repair, update, or completely reinstall ZChat."
    echo ""
    # Check if ZChat is already installed
    ZCHAT_INSTALLED=false
    ZCHAT_CONFIG_DIR="$HOME/.config/zchat"
    ZCHAT_BIN_DIR="$HOME/.local/bin"

    # Check for system installation (installed to user directories)
    local system_installed=false
    if [ -f "$ZCHAT_CONFIG_DIR/user.yaml" ]; then
        system_installed=true
        print_info "ZChat configuration found"
    fi

    # Check for installed binary in standard locations
    local binary_installed=false
    if [ -f "$ZCHAT_BIN_DIR/z" ] || [ -f "$ZCHAT_BIN_DIR/zchat" ]; then
        binary_installed=true
        print_info "ZChat binary found in $ZCHAT_BIN_DIR"
    fi

    # Check for binary in system PATH (but not source file)
    local binary_in_path=false
    if command -v z >/dev/null 2>&1; then
        local z_path=$(command -v z)
        # Only consider it installed if it's not the source file
        if [ "$z_path" != "$(pwd)/z" ] && [ "$z_path" != "./z" ]; then
            binary_in_path=true
            print_info "ZChat command found in PATH: $z_path"
        fi
    fi

    # Only consider it a system installation if it's actually installed, not just source
    if [ "$system_installed" = true ] || [ "$binary_in_path" = true ] || [ "$binary_installed" = true ]; then
        ZCHAT_INSTALLED=true
        print_info "Existing ZChat installation detected"
    elif [ -f "./z" ]; then
        print_info "ZChat source found in current directory (not installed)"
        print_info "Run ./install.sh to install ZChat"
    fi

    if [ "$ZCHAT_INSTALLED" = true ]; then
        echo ""
        echo "Choose repair action:"
        echo ""
        echo -e "${LIGHT_BLUE}1. Repair Dependencies${NC}"
        echo "   - Reinstall missing or corrupted Perl modules"
        echo "   - Keep existing configuration and data"
        echo ""
        echo -e "${LIGHT_BLUE}2. Update Installation${NC}"
        echo "   - Reinstall ZChat with latest version"
        echo "   - Preserve configuration and data"
        echo ""
        echo -e "${LIGHT_BLUE}3. Force Reinstall${NC}"
        echo "   - Complete reinstall, overwrite everything"
        echo "   - Backup existing config first"
        echo ""
        echo -e "${LIGHT_BLUE}4. Clean Uninstall${NC}"
        echo "   - Remove ZChat completely"
        echo "   - Clean up all files and dependencies"
        echo ""
        echo -e "${LIGHT_BLUE}5. Diagnose Issues${NC}"
        echo "   - Check installation health"
        echo "   - Identify problems"
        echo ""
        echo -e "${LIGHT_BLUE}6. Restore from Backup${NC}"
        echo "   - Restore from previous backup"
        echo "   - Recover from failed operations"
        echo ""
    else
        echo "No existing ZChat installation found."
        echo "Run the standard installer instead: ./install.sh"
        exit 0
    fi

    read -p "Choose action (1-6): " -r
    echo ""

    case $REPLY in
        1)
            print_info "Selected: Repair Dependencies"
            repair_dependencies
            ;;
        2)
            print_info "Selected: Update Installation"
            update_installation
            ;;
        3)
            print_info "Selected: Force Reinstall"
            force_reinstall
            ;;
        4)
            print_info "Selected: Clean Uninstall"
            clean_uninstall
            ;;
        5)
            print_info "Selected: Diagnose Issues"
            diagnose_issues
            ;;
        6)
            print_info "Selected: Restore from Backup"
            restore_from_backup_menu
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
}

# Function to repair dependencies
repair_dependencies() {
    echo ""
    print_info "Repairing ZChat dependencies..."
    
    # Run pre-flight checks
    if ! preflight_checks; then
        print_error "Pre-flight checks failed. Cannot proceed with repair."
        return 1
    fi
    
    # Setup local::lib with retry logic
    print_info "Setting up Perl environment..."
    if ! retry_operation 3 2 "eval \$(perl -I ~/perl5/lib/perl5/ -Mlocal::lib) 2>/dev/null" "Perl environment setup"; then
        print_warning "Failed to setup Perl environment, continuing anyway"
    fi
    
    # Install cpanm if missing with retry logic
    if ! command -v cpanm >/dev/null 2>&1; then
        print_info "Installing cpanm..."
        if ! retry_operation 3 2 "curl -L https://cpanmin.us | perl - App::cpanminus 2>/dev/null" "cpanm installation"; then
            print_error "Failed to install cpanm after 3 retries"
            print_warning "This may indicate:"
            print_warning "  - No internet connection"
            print_warning "  - Firewall blocking downloads"
            print_warning "  - DNS resolution issues"
            print_info "Try installing cpanm manually:"
            print_info "  curl -L https://cpanmin.us | perl - App::cpanminus"
            return 1
        fi
    fi
    
    # Required modules (minimal set)
    if [ -f "./install/install-common.sh" ]; then
        source ./install/install-common.sh
    elif [ -f "./install-common.sh" ]; then
        source ./install-common.sh
        modules=($(export_core_modules))
    else
        print_error "install-common.sh not found"
        exit 1
    fi
    
    print_info "Checking and repairing modules..."
    total_modules=${#modules[@]}
    current_module=0
    start_time=$(date +%s)
    
    for module in "${modules[@]}"; do
        current_module=$((current_module + 1))
        
        if perl -e "use $module; 1" 2>/dev/null; then
            show_enhanced_progress $current_module $total_modules "$module (OK)" "success" $start_time
        else
            show_progress_bar $current_module $total_modules "Repairing $module" $start_time
            
            # Find cpanm in the right location
            CPANM_CMD="cpanm"
            if [ -f "$HOME/perl5/bin/cpanm" ]; then
                CPANM_CMD="$HOME/perl5/bin/cpanm"
            elif [ -f "/usr/local/bin/cpanm" ]; then
                CPANM_CMD="/usr/local/bin/cpanm"
            fi
            
            if retry_operation 3 2 "$CPANM_CMD --notest --quiet $module 2>/dev/null" "$module repair"; then
                show_enhanced_progress $current_module $total_modules "$module" "success" $start_time
            else
                show_enhanced_progress $current_module $total_modules "$module" "failed" $start_time
                print_error "Failed to repair $module after 3 retries"
                print_warning "This may indicate:"
                print_warning "  - Network connectivity issues"
                print_warning "  - CPAN server problems"
                print_warning "  - Insufficient disk space"
                print_warning "  - Permission issues"
                print_info "Try running: $CPANM_CMD $module"
            fi
        fi
    done
    
    print_status "Dependency repair completed!"
}

# Function to update installation
update_installation() {
    echo ""
    print_info "Updating ZChat installation..."
    
    # Create rollback state
    local rollback_state=""
    local backup_timestamp=$(date +%s)
    
    # Backup existing config
    if [ -d "$ZCHAT_CONFIG_DIR" ]; then
        print_info "Backing up existing configuration..."
        local config_backup="$ZCHAT_CONFIG_DIR.backup.$backup_timestamp"
        if cp -r "$ZCHAT_CONFIG_DIR" "$config_backup"; then
            rollback_state="$config_backup"
            print_status "Configuration backed up to: $config_backup"
        else
            print_error "Failed to backup configuration"
            print_warning "Continuing without backup..."
        fi
    fi
    
    # Update ZChat files
    print_info "Updating ZChat files..."
    if [ -f "./z/z" ]; then
        if cp "./z/z" "$ZCHAT_BIN_DIR/z" 2>/dev/null; then
            chmod +x "$ZCHAT_BIN_DIR/z"
            print_status "Updated ZChat binary"
        else
            print_error "Failed to update ZChat binary"
            print_warning "Continuing with existing binary..."
        fi
    else
        print_warning "ZChat binary not found in ./z/z"
    fi
    
    # Update libraries
    if [ -d "./z/lib" ]; then
        print_info "Updating ZChat libraries..."
        if cp -r "./z/lib" "$ZCHAT_BIN_DIR/" 2>/dev/null; then
            print_status "Updated ZChat libraries"
        else
            print_error "Failed to update ZChat libraries"
            print_warning "Continuing with existing libraries..."
        fi
    else
        print_warning "ZChat libraries not found in ./z/lib"
    fi
    
    # Repair dependencies
    if repair_dependencies; then
        print_status "ZChat updated successfully!"
        if [ -n "$rollback_state" ]; then
            print_info "Rollback state available: $rollback_state"
        fi
    else
        print_error "Dependency repair failed"
        print_warning "Update may be incomplete"
        if [ -n "$rollback_state" ]; then
            print_info "Configuration backup available for rollback: $rollback_state"
        fi
        return 1
    fi
}

# Function to force reinstall
force_reinstall() {
    echo ""
    print_warning "This will completely reinstall ZChat!"
    print_warning "Existing configuration will be backed up."
    echo ""
    read -p "Continue? (y/N): " -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Cancelled"
        exit 0
    fi
    
    # Backup existing installation
    print_info "Backing up existing installation..."
    BACKUP_DIR="$HOME/.zchat-backup-$(date +%s)"
    mkdir -p "$BACKUP_DIR"
    
    local backup_success=true
    
    if [ -d "$ZCHAT_CONFIG_DIR" ]; then
        if cp -r "$ZCHAT_CONFIG_DIR" "$BACKUP_DIR/config"; then
            print_status "Configuration backed up"
        else
            print_error "Failed to backup configuration"
            backup_success=false
        fi
    fi
    
    if [ -f "$ZCHAT_BIN_DIR/z" ]; then
        if cp "$ZCHAT_BIN_DIR/z" "$BACKUP_DIR/z"; then
            print_status "Binary backed up"
        else
            print_error "Failed to backup binary"
            backup_success=false
        fi
    fi
    
    # Validate backup integrity
    if [ "$backup_success" = true ]; then
        if validate_backup "$BACKUP_DIR"; then
            print_status "Backup created and validated successfully"
        else
            print_error "Backup validation failed"
            backup_success=false
        fi
    fi
    
    if [ "$backup_success" = false ]; then
        print_error "Backup creation failed"
        print_warning "Continuing without backup (not recommended)"
    fi
    
    # Clean install
    print_info "Performing clean installation..."
    local install_success=false
    
    if [ -f "./install.sh" ]; then
        if ./install.sh --force; then
            install_success=true
        fi
    elif [ -f "../install.sh" ]; then
        if ../install.sh --force; then
            install_success=true
        fi
    else
        print_error "install.sh not found"
        print_warning "Expected locations:"
        print_warning "  - ./install.sh (current directory)"
        print_warning "  - ../install.sh (parent directory)"
        print_warning "Restoring from backup..."
        restore_from_backup "$BACKUP_DIR"
        exit 1
    fi
    
    if [ "$install_success" = true ]; then
        print_status "Force reinstall completed!"
        print_info "Backup saved to: $BACKUP_DIR"
    else
        print_error "Force reinstall failed"
        print_warning "Restoring from backup..."
        restore_from_backup "$BACKUP_DIR"
        return 1
    fi
}

# Function to detect installation type using comprehensive detection
detect_installation_type() {
    # Use comprehensive installation detector if available
    if [ -f "./install/installation-detector.sh" ]; then
        source ./install/installation-detector.sh
        detect_all_installations
        get_installation_summary
    else
        # Fallback to basic detection
        detect_basic_installation_type
    fi
}

# Basic installation type detection (fallback)
detect_basic_installation_type() {
    local install_type="unknown"
    local detected_types=()
    
    # Check for standard installations (platform-sensitive)
    local config_dir
    if [ -n "$XDG_CONFIG_HOME" ]; then
        config_dir="$XDG_CONFIG_HOME/zchat"
    elif [ "$OS_TYPE" = "windows" ]; then
        config_dir="${APPDATA:-$HOME/AppData/Roaming}/zchat"
    elif [ "$OS_TYPE" = "macos" ]; then
        config_dir="$HOME/Library/Application Support/zchat"
    else
        config_dir="$HOME/.config/zchat"
    fi
    
    # Check for standard installations
    if [ -d "$config_dir" ]; then
        detected_types+=("standard")
    fi
    
    # Check for bundle installations
    if [ -d "zchat-static-bundle" ] || [ -d "zchat-bundle-optimized" ] || \
       find . -maxdepth 1 -name "zchat-bundle-*" -type d | grep -q .; then
        detected_types+=("bundle")
    fi
    
    # Check for single executable installations
    if find . -maxdepth 1 -name "zchat-*-*-*" -type f | grep -q . || \
       find . -maxdepth 1 -name "zchat-single-*" -type d | grep -q .; then
        detected_types+=("single")
    fi
    
    # Check for platform-specific bundles
    if find . -maxdepth 1 -name "zchat-bundle-*-*" -type d | grep -q .; then
        detected_types+=("platform")
    fi
    
    # Check for optimized bundles
    if [ -d "zchat-bundle-optimized" ]; then
        detected_types+=("optimized")
    fi
    
    # Check for archive files
    if find . -maxdepth 1 -name "zchat-*.tar.gz" -type f | grep -q .; then
        detected_types+=("archives")
    fi
    
    # Check for bundle-specific Perl libraries
    if [ -d "$HOME/.local/bin/perl-lib" ]; then
        detected_types+=("perl-lib")
    fi
    
    if [ ${#detected_types[@]} -eq 0 ]; then
        install_type="none"
    elif [ ${#detected_types[@]} -eq 1 ]; then
        install_type="${detected_types[0]}"
    else
        install_type="mixed"
    fi
    
    echo "$install_type"
}

# Function to cleanup bundle files
cleanup_bundle_files() {
    # Temporarily disable set -e for this function
    set +e
    print_info "Cleaning up bundle installations..."
    local cleanup_items=()
    local total_items=0
    
    # Collect bundle directories
    for bundle_dir in zchat-static-bundle zchat-bundle-optimized; do
        if [ -d "$bundle_dir" ]; then
            cleanup_items+=("$bundle_dir")
            ((total_items++))
        fi
    done
    
    # Collect platform-specific bundles
    while IFS= read -r -d '' bundle_dir; do
        cleanup_items+=("$bundle_dir")
        ((total_items++))
    done < <(find . -maxdepth 1 -name "zchat-bundle-*" -type d -print0 2>/dev/null)
    
    # Collect bundle-specific Perl libraries
    if [ -d "$HOME/.local/bin/perl-lib" ]; then
        cleanup_items+=("$HOME/.local/bin/perl-lib")
        ((total_items++))
    fi
    
    if [ $total_items -eq 0 ]; then
        print_info "No bundle files found to clean up"
        return 0
    fi
    
    print_info "Found $total_items bundle items to remove"
    local current_item=0
    local start_time=$(date +%s)
    
    for item in "${cleanup_items[@]}"; do
        current_item=$((current_item + 1))
        local item_name=$(basename "$item")
        
        # Show progress bar even for single items
        show_progress_bar $current_item $total_items "Removing $item_name" $start_time
        
        if rm -rf "$item" 2>/dev/null; then
            show_enhanced_progress $current_item $total_items "$item_name" "success" $start_time
        else
            show_enhanced_progress $current_item $total_items "$item_name" "failed" $start_time
            print_warning "Failed to remove: $item"
        fi
    done
    
    print_status "Bundle cleanup completed!"
}

# Function to cleanup single executable files
cleanup_single_executable_files() {
    # Temporarily disable set -e for this function
    set +e
    print_info "Cleaning up single executable installations..."
    local cleanup_items=()
    local total_items=0
    
    # Collect single executables
    while IFS= read -r -d '' executable; do
        cleanup_items+=("$executable")
        ((total_items++))
    done < <(find . -maxdepth 1 -name "zchat-*-*-*" -type f -print0 2>/dev/null)
    
    # Collect single executable directories
    while IFS= read -r -d '' directory; do
        cleanup_items+=("$directory")
        ((total_items++))
    done < <(find . -maxdepth 1 -name "zchat-single-*" -type d -print0 2>/dev/null)
    
    if [ $total_items -eq 0 ]; then
        print_info "No single executable files found to clean up"
        return 0
    fi
    
    print_info "Found $total_items single executable items to remove"
    local current_item=0
    local start_time=$(date +%s)
    
    for item in "${cleanup_items[@]}"; do
        current_item=$((current_item + 1))
        local item_name=$(basename "$item")
        
        # Show progress bar even for single items
        show_progress_bar $current_item $total_items "Removing $item_name" $start_time
        
        if rm -rf "$item" 2>/dev/null; then
            show_enhanced_progress $current_item $total_items "$item_name" "success" $start_time
        else
            show_enhanced_progress $current_item $total_items "$item_name" "failed" $start_time
            print_warning "Failed to remove: $item"
        fi
    done
    
    print_status "Single executable cleanup completed!"
}

# Function to cleanup archive files
cleanup_archive_files() {
    # Temporarily disable set -e for this function
    set +e
    print_info "Cleaning up distribution archives..."
    local cleanup_items=()
    local total_items=0
    
    # Collect archive files
    while IFS= read -r -d '' archive; do
        cleanup_items+=("$archive")
        ((total_items++))
    done < <(find . -maxdepth 1 -name "zchat-*.tar.gz" -type f -print0 2>/dev/null)
    
    if [ $total_items -eq 0 ]; then
        print_info "No archive files found to clean up"
        return 0
    fi
    
    print_info "Found $total_items archive files to remove"
    local current_item=0
    local start_time=$(date +%s)
    
    for item in "${cleanup_items[@]}"; do
        current_item=$((current_item + 1))
        local item_name=$(basename "$item")
        local item_size=$(du -h "$item" 2>/dev/null | cut -f1)
        
        # Show progress bar even for single items
        show_progress_bar $current_item $total_items "Removing $item_name ($item_size)" $start_time
        
        if rm -f "$item" 2>/dev/null; then
            show_enhanced_progress $current_item $total_items "$item_name ($item_size)" "success" $start_time
        else
            show_enhanced_progress $current_item $total_items "$item_name ($item_size)" "failed" $start_time
            print_warning "Failed to remove: $item"
        fi
    done
    
    print_status "Archive cleanup completed!"
}

# Function to cleanup standard installation
cleanup_standard_installation() {
    # Temporarily disable set -e for this function
    set +e
    print_info "Cleaning up standard installation..."
    local cleanup_items=()
    local total_items=0
    
    # Collect standard installation files
    if [ -f "$ZCHAT_BIN_DIR/z" ]; then
        cleanup_items+=("$ZCHAT_BIN_DIR/z")
        ((total_items++))
    fi
    
    if [ -f "$ZCHAT_BIN_DIR/zchat" ]; then
        cleanup_items+=("$ZCHAT_BIN_DIR/zchat")
        ((total_items++))
    fi
    
    if [ -d "$ZCHAT_CONFIG_DIR" ]; then
        cleanup_items+=("$ZCHAT_CONFIG_DIR")
        ((total_items++))
    fi
    
    # Find and remove actual z command if it exists in PATH
    if command -v z >/dev/null 2>&1; then
        local z_path=$(command -v z)
        if [ -f "$z_path" ] && [ "$z_path" != "$(pwd)/z" ] && [ "$z_path" != "./z" ]; then
            cleanup_items+=("$z_path")
            ((total_items++))
        fi
    fi
    
    if [ $total_items -eq 0 ]; then
        print_info "No standard installation files found to clean up"
        return 0
    fi
    
    print_info "Found $total_items standard installation items to remove"
    local current_item=0
    local start_time=$(date +%s) || start_time=$(date +%s)
    
    for item in "${cleanup_items[@]}"; do
        current_item=$((current_item + 1)) || current_item=1
        local item_name=$(basename "$item") || item_name="unknown"
        
        # Show progress bar even for single items
        show_progress_bar $current_item $total_items "Removing $item_name" $start_time
        
        # Use a more robust removal approach that doesn't fail with set -e
        if rm -rf "$item" 2>/dev/null || true; then
            show_enhanced_progress $current_item $total_items "$item_name" "success" $start_time
        else
            show_enhanced_progress $current_item $total_items "$item_name" "failed" $start_time
            print_warning "Failed to remove: $item"
        fi
    done
    
    print_status "Standard installation cleanup completed!"
}

# Function to cleanup Perl libraries
cleanup_perl_libraries() {
    # Temporarily disable set -e for this function
    set +e
    echo ""
    print_warning "WARNING: Removing Perl modules may affect other applications!"
    print_warning "ZChat modules may be shared with other Perl applications."
    echo ""
    read -p "Remove ZChat Perl modules? (y/N): " -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Skipping Perl module removal"
        return 0
    fi
    
    print_info "Cleaning up Perl libraries..."
    local cleanup_items=()
    local total_items=0
    
    # Check for local Perl installation
    if [ -d "$HOME/perl5" ] && [ -f "$HOME/perl5/bin/cpanm" ]; then
        print_warning "Found local Perl installation in ~/perl5"
        print_warning "This may contain modules for other applications too!"
        echo ""
        read -p "Are you sure you want to remove ~/perl5? (y/N): " -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cleanup_items+=("$HOME/perl5")
            ((total_items++))
        fi
    fi
    
    # Check for bundle-specific Perl libraries
    if [ -d "$HOME/.local/bin/perl-lib" ]; then
        cleanup_items+=("$HOME/.local/bin/perl-lib")
        ((total_items++))
    fi
    
    if [ $total_items -eq 0 ]; then
        print_info "No Perl libraries found to clean up"
        return 0
    fi
    
    print_info "Found $total_items Perl library items to remove"
    local current_item=0
    local start_time=$(date +%s)
    
    for item in "${cleanup_items[@]}"; do
        current_item=$((current_item + 1))
        local item_name=$(basename "$item")
        
        # Show progress bar even for single items
        show_progress_bar $current_item $total_items "Removing $item_name" $start_time
        
        if rm -rf "$item" 2>/dev/null; then
            show_enhanced_progress $current_item $total_items "$item_name" "success" $start_time
        else
            show_enhanced_progress $current_item $total_items "$item_name" "failed" $start_time
            print_warning "Failed to remove: $item"
        fi
    done
    
    print_status "Perl library cleanup completed!"
}

# Function to cleanup PATH entries
cleanup_path_entries() {
    # Temporarily disable set -e for this function
    set +e
    print_info "Checking PATH configuration..."
    local shell_config=""
    case "$SHELL" in
        */bash)
            shell_config="$HOME/.bashrc"
            ;;
        */zsh)
            shell_config="$HOME/.zshrc"
            ;;
        */fish)
            shell_config="$HOME/.config/fish/config.fish"
            ;;
        *)
            shell_config="$HOME/.profile"
            ;;
    esac
    
    if [ -f "$shell_config" ]; then
        # Check if PATH contains ZChat bin directory
        if grep -q "$ZCHAT_BIN_DIR" "$shell_config" 2>/dev/null; then
            print_warning "Found PATH entry in $shell_config"
            print_warning "You may need to manually remove: export PATH=\"\$HOME/.local/bin:\$PATH\""
            print_info "Consider running: sed -i '/$ZCHAT_BIN_DIR/d' $shell_config"
        else
            print_info "No PATH entries found in $shell_config"
        fi
    else
        print_warning "Shell config file not found: $shell_config"
    fi
}

# Function to clean uninstall
clean_uninstall() {
    echo ""
    print_warning "This will completely remove ZChat!"
    print_warning "All configuration and data will be lost."
    echo ""
    
    # Detect installation type
    local install_type=$(detect_installation_type)
    print_info "Detected installation type: $install_type"
    
    # Show what will be removed
    echo ""
    print_info "The following will be removed:"
    
    case $install_type in
        "standard")
            echo "  • Standard installation files (~/.local/bin/z, ~/.config/zchat/)"
            ;;
        "bundle")
            echo "  • Bundle directories (zchat-static-bundle/, zchat-bundle-*/)"
            echo "  • Bundle-specific Perl libraries (~/.local/bin/perl-lib/)"
            ;;
        "single")
            echo "  • Single executable files (zchat-*-*-*)"
            echo "  • Single executable directories (zchat-single-*/)"
            ;;
        "platform")
            echo "  • Platform-specific bundles (zchat-bundle-*-*/)"
            ;;
        "optimized")
            echo "  • Optimized bundles (zchat-bundle-optimized/)"
            ;;
        "archives")
            echo "  • Distribution archives (zchat-*.tar.gz)"
            ;;
        "mixed")
            echo "  • Multiple installation types detected"
            echo "  • All ZChat-related files and directories"
            ;;
        "none")
            print_warning "No ZChat installation detected"
            return 0
            ;;
        *)
            echo "  • All ZChat-related files and directories"
            ;;
    esac
    
    echo ""
    read -p "Continue? (y/N): " -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Cancelled"
        exit 0
    fi
    
    # Comprehensive cleanup with progress bars
    print_info "Starting comprehensive ZChat cleanup..."
    echo ""
    
    # Cleanup standard installation
    cleanup_standard_installation
    echo ""
    
    # Cleanup bundle files
    cleanup_bundle_files
    echo ""
    
    # Cleanup single executable files
    cleanup_single_executable_files
    echo ""
    
    # Cleanup archive files
    cleanup_archive_files
    echo ""
    
    # Cleanup Perl libraries
    cleanup_perl_libraries
    echo ""
    
    # Cleanup PATH entries
    cleanup_path_entries
    echo ""
    
    print_status "ZChat completely removed!"
    print_info "Cleanup summary:"
    print_info "  • All ZChat binaries removed"
    print_info "  • All configuration files removed"
    print_info "  • All bundle directories removed"
    print_info "  • All single executables removed"
    print_info "  • All distribution archives removed"
    print_info "  • PATH entries identified for manual removal"
}

# Function to diagnose issues
diagnose_issues() {
    echo ""
    print_info "Diagnosing ZChat installation..."
    echo ""
    
    # Check Perl version
    print_info "Perl version:"
    perl -v | head -2
    
    # Check ZChat binary
    print_info "ZChat binary:"
    if [ -f "$ZCHAT_BIN_DIR/z" ]; then
        print_status "Found: $ZCHAT_BIN_DIR/z"
        ls -la "$ZCHAT_BIN_DIR/z"
    else
        print_error "Not found: $ZCHAT_BIN_DIR/z"
    fi
    
    # Check configuration
    print_info "Configuration:"
    if [ -d "$ZCHAT_CONFIG_DIR" ]; then
        print_status "Found: $ZCHAT_CONFIG_DIR"
        ls -la "$ZCHAT_CONFIG_DIR"
    else
        print_error "Not found: $ZCHAT_CONFIG_DIR"
    fi
    
    # Check Perl modules
    print_info "Perl modules:"
    if [ -f "./install/install-common.sh" ]; then
        source ./install/install-common.sh
    elif [ -f "./install-common.sh" ]; then
        source ./install-common.sh
        modules=($(export_critical_modules))
    else
        modules=("Mojo::UserAgent" "JSON::XS" "YAML::XS" "Text::Xslate")
    fi
    for module in "${modules[@]}"; do
        if perl -e "use $module; 1" 2>/dev/null; then
            print_status "$module"
        else
            print_error "$module (missing)"
        fi
    done
    
    # Check PATH
    print_info "PATH configuration:"
    if echo "$PATH" | grep -q "$ZCHAT_BIN_DIR"; then
        print_status "ZChat bin directory in PATH"
    else
        print_warning "ZChat bin directory not in PATH"
        print_info "Add to ~/.bashrc: export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
    
    # Check environment
    print_info "Environment variables:"
    if [ -n "$OPENAI_API_KEY" ]; then
        print_status "OPENAI_API_KEY set"
    else
        print_warning "OPENAI_API_KEY not set"
    fi
    
    if [ -n "$LLAMA_URL" ]; then
        print_status "LLAMA_URL set: $LLAMA_URL"
    else
        print_warning "LLAMA_URL not set"
    fi
    
    print_status "Diagnosis completed!"
}

# Function to validate backup integrity
validate_backup() {
    local backup_dir="$1"
    local errors=0
    
    print_info "Validating backup integrity: $backup_dir"
    
    # Check if backup directory exists
    if [ ! -d "$backup_dir" ]; then
        print_error "Backup directory not found: $backup_dir"
        return 1
    fi
    
    # Check for essential files
    local essential_files=("config" "z")
    for file in "${essential_files[@]}"; do
        if [ ! -e "$backup_dir/$file" ]; then
            print_warning "Missing essential file: $file"
            ((errors++))
        fi
    done
    
    # Check config directory structure
    if [ -d "$backup_dir/config" ]; then
        if [ ! -f "$backup_dir/config/user.yaml" ]; then
            print_warning "Missing user.yaml in config backup"
            ((errors++))
        fi
    fi
    
    # Check binary permissions
    if [ -f "$backup_dir/z" ]; then
        if [ ! -x "$backup_dir/z" ]; then
            print_warning "Backup binary is not executable"
            ((errors++))
        fi
    fi
    
    if [ $errors -eq 0 ]; then
        print_status "Backup validation passed"
        return 0
    else
        print_error "Backup validation failed with $errors errors"
        print_warning "Backup may be corrupted or incomplete"
        return 1
    fi
}

# Function to restore from backup
restore_from_backup() {
    local backup_dir="$1"
    
    # Validate backup first
    if ! validate_backup "$backup_dir"; then
        print_error "Cannot restore from invalid backup"
        return 1
    fi
    
    print_info "Restoring from backup: $backup_dir"
    
    # Restore configuration
    if [ -d "$backup_dir/config" ]; then
        print_info "Restoring configuration..."
        if cp -r "$backup_dir/config" "$ZCHAT_CONFIG_DIR"; then
            print_status "Configuration restored"
        else
            print_error "Failed to restore configuration"
            return 1
        fi
    fi
    
    # Restore binary
    if [ -f "$backup_dir/z" ]; then
        print_info "Restoring binary..."
        if cp "$backup_dir/z" "$ZCHAT_BIN_DIR/z"; then
            chmod +x "$ZCHAT_BIN_DIR/z"
            print_status "Binary restored"
        else
            print_error "Failed to restore binary"
            return 1
        fi
    fi
    
    print_status "Restore completed"
}

# Function to show backup restoration menu
restore_from_backup_menu() {
    echo ""
    print_info "Available backups:"
    echo ""
    
    # Find all backup directories
    local backups=()
    for backup in "$HOME"/.zchat-backup-*; do
        if [ -d "$backup" ]; then
            backups+=("$backup")
        fi
    done
    
    # Find config backups
    for backup in "$HOME"/.config/zchat.backup.*; do
        if [ -d "$backup" ]; then
            backups+=("$backup")
        fi
    done
    
    if [ ${#backups[@]} -eq 0 ]; then
        print_warning "No backups found"
        print_info "Backups are created during updates and force reinstalls"
        return 0
    fi
    
    # Show available backups
    local i=1
    for backup in "${backups[@]}"; do
        local backup_name=$(basename "$backup")
        local backup_date=$(stat -c %y "$backup" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1)
        echo -e "${LIGHT_BLUE}$i. $backup_name${NC}"
        echo "   Created: $backup_date"
        echo "   Path: $backup"
        echo ""
        ((i++))
    done
    
    echo "0. Cancel"
    echo ""
    read -p "Select backup to restore (0-${#backups[@]}): " -r
    echo ""
    
    if [ "$REPLY" = "0" ]; then
        print_info "Cancelled"
        return 0
    fi
    
    if [ "$REPLY" -ge 1 ] && [ "$REPLY" -le ${#backups[@]} ]; then
        local selected_backup="${backups[$((REPLY-1))]}"
        print_info "Selected backup: $selected_backup"
        
        echo ""
        print_warning "This will overwrite current ZChat installation!"
        read -p "Continue? (y/N): " -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            restore_from_backup "$selected_backup"
        else
            print_info "Cancelled"
        fi
    else
        print_error "Invalid selection"
    fi
}

# Note: LLM configuration is handled separately
# Users can configure their LLM server after repair using:
# ./install/api-config.sh

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main
    
    echo ""
    print_status "Repair operation completed!"
    
    # Run post-installation tests
    echo ""
    print_info "Running post-installation tests..."
    if post_install_test; then
        print_status "✓ All tests passed!"
    else
        print_warning "⚠ Some tests failed, but repair may still be successful"
    fi
    
    echo ""
    echo "Next steps:"
    echo "1. Test ZChat: z --status"
    echo "2. Configure LLM server: ./install/api-config.sh"
    echo "3. Run: z --help for usage information"
fi