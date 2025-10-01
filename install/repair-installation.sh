#!/bin/bash
# ZChat Installation Repair Script v0.8b
# Enhanced repair with progress bars, retry logic, and validation

set -e

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
        printf "\r[%3d%%] %s (%d/%d)" $percent "$desc" $current $total
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

# Parse command line arguments
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

# Setup logging
setup_logging

echo "ZChat Installation Repair Tool"
echo "==============================="
echo ""
echo "This tool can repair, update, or completely reinstall ZChat."
echo ""

# Main execution logic
main() {
    # Check if ZChat is already installed
    ZCHAT_INSTALLED=false
    ZCHAT_CONFIG_DIR="$HOME/.config/zchat"
    ZCHAT_BIN_DIR="$HOME/.local/bin"

    if [ -f "$ZCHAT_CONFIG_DIR/user.yaml" ]; then
        ZCHAT_INSTALLED=true
        print_info "Existing ZChat installation detected"
    fi

    if [ -f "$ZCHAT_BIN_DIR/z" ] || [ -f "$ZCHAT_BIN_DIR/zchat" ]; then
        ZCHAT_INSTALLED=true
        print_info "ZChat binary found in $ZCHAT_BIN_DIR"
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

# Function to clean uninstall
clean_uninstall() {
    echo ""
    print_warning "This will completely remove ZChat!"
    print_warning "All configuration and data will be lost."
    echo ""
    read -p "Continue? (y/N): " -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Cancelled"
        exit 0
    fi
    
    # Remove binaries
    print_info "Removing ZChat binaries..."
    rm -f "$ZCHAT_BIN_DIR/z"
    rm -f "$ZCHAT_BIN_DIR/zchat"
    
    # Remove configuration
    print_info "Removing configuration..."
    rm -rf "$ZCHAT_CONFIG_DIR"
    
    # Remove Perl modules (optional) - SAFETY WARNING
    echo ""
    print_warning "WARNING: Removing Perl modules may affect other applications!"
    print_warning "ZChat modules may be shared with other Perl applications."
    echo ""
    read -p "Remove ZChat Perl modules? (y/N): " -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Checking for ZChat-specific Perl installations..."
        
        # Only remove if we can safely identify ZChat-specific installations
        if [ -d "$HOME/perl5" ] && [ -f "$HOME/perl5/bin/cpanm" ]; then
            print_warning "Found local Perl installation in ~/perl5"
            print_warning "This may contain modules for other applications too!"
            echo ""
            read -p "Are you sure you want to remove ~/perl5? (y/N): " -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                print_info "Removing ~/perl5 (this may affect other applications)..."
                rm -rf "$HOME/perl5"
                print_status "Removed ~/perl5"
            else
                print_info "Skipping Perl module removal"
            fi
        else
            print_info "No local Perl installation found in ~/perl5"
            print_warning "ZChat modules may be installed system-wide"
            print_warning "Manual cleanup may be needed if modules were installed globally"
        fi
    fi
    
    print_status "ZChat completely removed!"
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
        modules=("Mojo::UserAgent" "JSON::XS" "YAML::XS" "Text::Xslate" "Clipboard")
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