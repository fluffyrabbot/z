#!/bin/bash
# ZChat Installation Repair Script v0.8b
# Enhanced repair with progress bars, retry logic, and validation

set -e

# Source progress utilities
if [ -f "./progress-utils.sh" ]; then
    source ./progress-utils.sh
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
    else
        echo "No existing ZChat installation found."
        echo "Run the standard installer instead: ./install-master.sh"
        exit 0
    fi

    read -p "Choose action (1-5): " -r
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
            print_error "Failed to install cpanm"
            return 1
        fi
    fi
    
    # Required modules (minimal set)
    if [ -f "./dependencies.sh" ]; then
        source ./dependencies.sh
        modules=($(export_core_modules))
    else
        print_error "dependencies.sh not found"
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
                print_error "Failed to repair $module after retries"
            fi
        fi
    done
    
    print_status "Dependency repair completed!"
}

# Function to update installation
update_installation() {
    echo ""
    print_info "Updating ZChat installation..."
    
    # Backup existing config
    if [ -d "$ZCHAT_CONFIG_DIR" ]; then
        print_info "Backing up existing configuration..."
        cp -r "$ZCHAT_CONFIG_DIR" "$ZCHAT_CONFIG_DIR.backup.$(date +%s)"
    fi
    
    # Update ZChat files
    print_info "Updating ZChat files..."
    if [ -f "./z/z" ]; then
        cp "./z/z" "$ZCHAT_BIN_DIR/z" 2>/dev/null || true
        chmod +x "$ZCHAT_BIN_DIR/z"
    fi
    
    # Update libraries
    if [ -d "./z/lib" ]; then
        print_info "Updating ZChat libraries..."
        cp -r "./z/lib" "$ZCHAT_BIN_DIR/" 2>/dev/null || true
    fi
    
    # Repair dependencies
    repair_dependencies
    
    print_status "ZChat updated successfully!"
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
    
    if [ -d "$ZCHAT_CONFIG_DIR" ]; then
        cp -r "$ZCHAT_CONFIG_DIR" "$BACKUP_DIR/config"
    fi
    
    if [ -f "$ZCHAT_BIN_DIR/z" ]; then
        cp "$ZCHAT_BIN_DIR/z" "$BACKUP_DIR/z"
    fi
    
    # Clean install
    print_info "Performing clean installation..."
    ./install.sh
    
    print_status "Force reinstall completed!"
    print_info "Backup saved to: $BACKUP_DIR"
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
    
    # Remove Perl modules (optional)
    echo ""
    read -p "Remove Perl modules? (y/N): " -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Removing Perl modules..."
        rm -rf "$HOME/perl5"
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
    if [ -f "./dependencies.sh" ]; then
        source ./dependencies.sh
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

# Configure API (optional)
if [ -f "./api-config.sh" ]; then
    echo ""
    read -p "Configure LLM server now? (y/N): " -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        source ./api-config.sh
        configure_api
        test_api_config
    fi
fi

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
    echo "2. Configure LLM server if needed"
    echo "3. Run: z --help for usage information"
fi