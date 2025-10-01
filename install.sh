#!/bin/bash
# ZChat Unified Installer v0.9
# Consolidated installer with all functionality in one script

set -e

# Source common utilities
if [ -f "./install/install-common.sh" ]; then
    source ./install/install-common.sh
else
    echo "Error: install-common.sh not found"
    exit 1
fi

# Installation modes
INSTALL_MODE="adaptive"  # standard, minimal, adaptive, single, bundle, platform, optimized, repair

# Check for help first
for arg in "$@"; do
    if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
        # Show help without initializing (to avoid side effects)
        echo "ZChat Unified Installer v0.9"
        echo ""
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Installation Modes:"
        echo "  (default)         Smart installation with environment detection"
        echo "  --minimal         Quick installation with core dependencies only"
        echo "  --standard        Standard installation with interactive prompts"
        echo "  --single          Create single executable (PAR Packer)"
        echo "  --bundle          Create static bundle (self-contained) [RECOMMENDED]"
        echo "  --platform        Create platform-specific bundles"
        echo "  --optimized       Create size-optimized bundle"
        echo "  --repair          Repair existing installation"
        echo ""
        echo "Options:"
        echo "  --verbose, -v     Verbose output"
        echo "  --force, -f       Force installation (overwrite existing)"
        echo "  --offline, -o    Offline installation mode"
        echo "  --help, -h        Show this help"
        echo ""
        echo "Examples:"
        echo "  $0                    # Smart installation (default)"
        echo "  $0 --minimal          # Minimal installation"
        echo "  $0 --standard         # Standard installation with prompts"
        echo "  $0 --bundle           # Create static bundle (recommended)"
        echo "  $0 --single           # Create single executable (PAR Packer)"
        echo "  $0 --platform         # Create platform-specific bundles"
        echo "  $0 --optimized        # Create size-optimized bundle"
        echo "  $0 --repair           # Repair existing installation"
        exit 0
    fi
done

# Initialize installer
init_installer

# Show help
show_help() {
    echo "ZChat Unified Installer v0.9"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Installation Modes:"
    echo "  (default)         Smart installation with environment detection"
    echo "  --minimal         Quick installation with core dependencies only"
    echo "  --standard        Standard installation with interactive prompts"
    echo "  --single          Create single executable (PAR Packer)"
    echo "  --bundle          Create static bundle (self-contained) [RECOMMENDED]"
    echo "  --platform        Create platform-specific bundles"
    echo "  --optimized       Create size-optimized bundle"
    echo "  --repair          Repair existing installation"
    echo ""
    echo "Options:"
    echo "  --verbose, -v     Verbose output"
    echo "  --force, -f       Force installation (overwrite existing)"
    echo "  --offline, -o    Offline installation mode"
    echo "  --help, -h        Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                    # Smart installation (default)"
    echo "  $0 --minimal          # Minimal installation"
    echo "  $0 --standard         # Standard installation with prompts"
    echo "  $0 --bundle           # Create static bundle (recommended)"
    echo "  $0 --single           # Create single executable (PAR Packer)"
    echo "  $0 --platform         # Create platform-specific bundles"
    echo "  $0 --optimized        # Create size-optimized bundle"
    echo "  $0 --repair           # Repair existing installation"
}

# Parse all arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --force|-f)
            FORCE=true
            shift
            ;;
        --offline|-o)
            OFFLINE=true
            shift
            ;;
        --minimal)
            INSTALL_MODE="minimal"
            shift
            ;;
        --adaptive)
            INSTALL_MODE="adaptive"
            shift
            ;;
        --single)
            INSTALL_MODE="single"
            shift
            ;;
        --bundle)
            INSTALL_MODE="bundle"
            shift
            ;;
        --platform)
            INSTALL_MODE="platform"
            shift
            ;;
        --optimized)
            INSTALL_MODE="optimized"
            shift
            ;;
        --repair)
            INSTALL_MODE="repair"
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check for existing installation
check_existing_installation() {
    # Check for system installation (installed to user directories)
    local system_installed=false
    if [ -f "$HOME/.config/zchat/user.yaml" ]; then
        system_installed=true
    fi
    
    # Check for binary in system PATH
    local binary_in_path=false
    if command -v z >/dev/null 2>&1; then
        local z_path=$(command -v z)
        # Only consider it installed if it's not the source file
        if [ "$z_path" != "$(pwd)/z" ] && [ "$z_path" != "./z" ]; then
            binary_in_path=true
        fi
    fi
    
    # Check for installed binary in standard locations
    local binary_installed=false
    if [ -f "$HOME/.local/bin/z" ] || [ -f "$HOME/.local/bin/zchat" ]; then
        binary_installed=true
    fi
    
    # Only consider it a system installation if it's actually installed, not just source
    if [ "$system_installed" = true ] || [ "$binary_in_path" = true ] || [ "$binary_installed" = true ]; then
        if [ "$FORCE" = "true" ]; then
            print_warning "Force flag detected - proceeding with fresh installation..."
            echo ""
            # Backup existing config
            backup_config "$HOME/.config/zchat/user.yaml"
        else
            print_warning "Existing ZChat installation detected!"
            echo ""
            echo "ZChat appears to already be installed on this system."
            echo "To avoid conflicts and preserve your existing setup, please use:"
            echo ""
            echo -e "  ${LIGHT_BLUE}$0 --repair${NC}"
            echo ""
            echo "The repair installer can:"
            echo "  • Fix dependency issues"
            echo "  • Update to the latest version"
            echo "  • Diagnose problems"
            echo "  • Clean uninstall if needed"
            echo ""
            echo "If you want to force a fresh installation anyway, run:"
            echo -e "  ${LIGHT_BLUE}$0 --force${NC}"
            echo ""
            echo -e "${RED}Exiting to protect existing installation.${NC}"
            echo "Use --force flag to override this protection."
            exit 0
        fi
    fi
}

# Standard installation
install_standard() {
    print_info "Starting standard installation..."
    
    # Run pre-flight checks
    if ! preflight_checks; then
        print_error "Pre-flight checks failed. Aborting installation."
        exit 1
    fi
    echo ""

    # Interactive dependency selection
    if [ "$OFFLINE" = "false" ]; then
        select_dependencies
        echo ""
    fi

    # Install system dependencies
    install_system_dependencies
    echo ""
    
    # Install dependencies
    print_info "Installing Perl dependencies..."
    echo ""
    
    if [ "$INSTALL_OPTIONAL" = "true" ]; then
        modules=($(export_all_modules))
    else
        modules=($(export_core_modules))
    fi
    
    if ! install_missing_modules "${modules[@]}"; then
        print_error "Dependency installation failed."
        exit 1
    fi

    # Make executable
    print_info "Making ZChat executable..."
    make_z_executable

    # Install binary to system PATH with progress
    print_info "Installing binary to system PATH..."
    mkdir -p "$HOME/.local/bin"
    
    # Show progress for binary installation
    local install_steps=("Installing binary" "Setting permissions")
    local total_steps=${#install_steps[@]}
    local current_step=0
    local start_time=$(date +%s)
    
    # Step 1: Copy binary
    current_step=$((current_step + 1))
    show_progress_bar $current_step $total_steps "${install_steps[0]}" $start_time
    
    if cp "./z" "$HOME/.local/bin/z"; then
        show_enhanced_progress $current_step $total_steps "${install_steps[0]}" "success" $start_time
    else
        show_enhanced_progress $current_step $total_steps "${install_steps[0]}" "failed" $start_time
        print_error "Failed to install binary to system PATH"
        exit 1
    fi
    
    # Step 2: Set permissions
    current_step=$((current_step + 1))
    show_progress_bar $current_step $total_steps "${install_steps[1]}" $start_time
    
    chmod +x "$HOME/.local/bin/z"
    show_enhanced_progress $current_step $total_steps "${install_steps[1]}" "success" $start_time
    
    print_status "Binary installed to $HOME/.local/bin/z"
    
    # Install lib directory with progress
    if [ -d "./lib" ]; then
        print_info "Installing library files..."
        
        # Show progress for library installation
        local lib_steps=("Copying library files" "Setting permissions")
        local lib_total=${#lib_steps[@]}
        local lib_current=0
        local lib_start_time=$(date +%s)
        
        # Step 1: Copy libraries
        lib_current=$((lib_current + 1))
        show_progress_bar $lib_current $lib_total "${lib_steps[0]}" $lib_start_time
        
        if cp -r "./lib" "$HOME/.local/bin/"; then
            show_enhanced_progress $lib_current $lib_total "${lib_steps[0]}" "success" $lib_start_time
        else
            show_enhanced_progress $lib_current $lib_total "${lib_steps[0]}" "failed" $lib_start_time
            print_error "Failed to install library files"
            exit 1
        fi
        
        # Step 2: Set permissions
        lib_current=$((lib_current + 1))
        show_progress_bar $lib_current $lib_total "${lib_steps[1]}" $lib_start_time
        
        chmod -R +x "$HOME/.local/bin/lib" 2>/dev/null || true
        show_enhanced_progress $lib_current $lib_total "${lib_steps[1]}" "success" $lib_start_time
        
        print_status "Library files installed to $HOME/.local/bin/lib"
    else
        print_error "lib directory not found"
        exit 1
    fi

    # Create configuration
    create_default_config

    # Detect and configure shell
    print_info "Configuring shell integration..."
    if detect_and_configure_shell; then
        print_status "Shell configuration detected"
    else
        print_warning "Shell configuration not found"
    fi

    # Run post-installation tests
    print_info "Running post-installation tests..."
    if post_install_test; then
        print_status "All tests passed!"
    else
        print_warning "Some tests failed, but installation may still work"
    fi
    echo ""

    # Configure API (optional)
    if [ -f "./install/api-config.sh" ]; then
        source ./install/api-config.sh
        configure_api
        test_api_config
    else
        show_api_setup_instructions
    fi

    show_completion_message
}

# Minimal installation
install_minimal() {
    print_info "Starting minimal installation..."
    
    # Run pre-flight checks
    if ! preflight_checks; then
        print_error "Pre-flight checks failed. Aborting installation."
        exit 1
    fi
    echo ""

    # Install system dependencies
    install_system_dependencies
    echo ""
    
    # Install only core dependencies
    print_info "Installing core dependencies only..."
    modules=($(export_core_modules))
    
    if ! install_missing_modules "${modules[@]}"; then
        print_error "Core dependency installation failed."
        exit 1
    fi

    # Make executable
    make_z_executable

    # Install binary to system PATH with progress
    print_info "Installing binary to system PATH..."
    mkdir -p "$HOME/.local/bin"
    
    # Show progress for binary installation
    local install_steps=("Installing binary" "Setting permissions")
    local total_steps=${#install_steps[@]}
    local current_step=0
    local start_time=$(date +%s)
    
    # Step 1: Copy binary
    current_step=$((current_step + 1))
    show_progress_bar $current_step $total_steps "${install_steps[0]}" $start_time
    
    if cp "./z" "$HOME/.local/bin/z"; then
        show_enhanced_progress $current_step $total_steps "${install_steps[0]}" "success" $start_time
    else
        show_enhanced_progress $current_step $total_steps "${install_steps[0]}" "failed" $start_time
        print_error "Failed to install binary to system PATH"
        exit 1
    fi
    
    # Step 2: Set permissions
    current_step=$((current_step + 1))
    show_progress_bar $current_step $total_steps "${install_steps[1]}" $start_time
    
    chmod +x "$HOME/.local/bin/z"
    show_enhanced_progress $current_step $total_steps "${install_steps[1]}" "success" $start_time
    
    print_status "Binary installed to $HOME/.local/bin/z"
    
    # Install lib directory with progress
    if [ -d "./lib" ]; then
        print_info "Installing library files..."
        
        # Show progress for library installation
        local lib_steps=("Copying library files" "Setting permissions")
        local lib_total=${#lib_steps[@]}
        local lib_current=0
        local lib_start_time=$(date +%s)
        
        # Step 1: Copy libraries
        lib_current=$((lib_current + 1))
        show_progress_bar $lib_current $lib_total "${lib_steps[0]}" $lib_start_time
        
        if cp -r "./lib" "$HOME/.local/bin/"; then
            show_enhanced_progress $lib_current $lib_total "${lib_steps[0]}" "success" $lib_start_time
        else
            show_enhanced_progress $lib_current $lib_total "${lib_steps[0]}" "failed" $lib_start_time
            print_error "Failed to install library files"
            exit 1
        fi
        
        # Step 2: Set permissions
        lib_current=$((lib_current + 1))
        show_progress_bar $lib_current $lib_total "${lib_steps[1]}" $lib_start_time
        
        chmod -R +x "$HOME/.local/bin/lib" 2>/dev/null || true
        show_enhanced_progress $lib_current $lib_total "${lib_steps[1]}" "success" $lib_start_time
        
        print_status "Library files installed to $HOME/.local/bin/lib"
    else
        print_error "lib directory not found"
        exit 1
    fi

    # Create basic configuration
    create_default_config

    print_status "Minimal installation complete!"
    echo ""
    echo "Note: This installation includes only core dependencies."
    echo "For full functionality, run: $0"
}

# Adaptive installation
install_adaptive() {
    print_info "Starting adaptive installation..."
    
    # Run pre-flight checks
    if ! preflight_checks; then
        print_error "Pre-flight checks failed. Aborting installation."
        exit 1
    fi
    echo ""

    # Detect environment
    if [ -f "./install/environment-detector.sh" ]; then
        source ./install/environment-detector.sh
        detect_environment
        print_info "Environment detection complete"
    else
        print_warning "Environment detector not found, using standard installation"
        install_standard
        return
    fi

    # Determine best installation method based on environment
    if [ "$OFFLINE" = "true" ]; then
        print_info "Offline mode detected, using minimal installation"
        install_minimal
    else
        print_info "Online mode detected, using standard installation"
        install_standard
    fi
}

# Single executable creation (PAR Packer)
create_single_executable() {
    print_info "Creating single executable (PAR Packer)..."
    
    if [ -f "./install/create-single-executable.sh" ]; then
        source ./install/create-single-executable.sh
        main  # Call the main function from create-single-executable.sh
    else
        print_error "Single executable creator not found"
        exit 1
    fi
}

# Static bundle creation
create_static_bundle() {
    print_info "Creating static bundle (self-contained)..."
    
    if [ -f "./install/create-bundle.sh" ]; then
        source ./install/create-bundle.sh
        # The create-bundle.sh script runs its main function automatically
    else
        print_error "Static bundle creator not found"
        exit 1
    fi
}

# Platform-specific bundle creation
create_platform_bundles() {
    print_info "Creating platform-specific bundles..."
    
    if [ -f "./install/create-platform-bundles.sh" ]; then
        source ./install/create-platform-bundles.sh
        main  # Call the main function from create-platform-bundles.sh
    else
        print_error "Platform bundle creator not found"
        exit 1
    fi
}

# Size-optimized bundle creation
create_optimized_bundle() {
    print_info "Creating size-optimized bundle..."
    
    if [ -f "./install/create-optimized-bundle.sh" ]; then
        source ./install/create-optimized-bundle.sh
        main  # Call the main function from create-optimized-bundle.sh
    else
        print_error "Optimized bundle creator not found"
        exit 1
    fi
}

# Repair installation
repair_installation() {
    print_info "Starting repair installation..."
    
    if [ -f "./install/repair-installation.sh" ]; then
        source ./install/repair-installation.sh
        main  # Call the main function from repair-installation.sh
    else
        print_error "Repair installer not found"
        exit 1
    fi
}

# Show API setup instructions
show_api_setup_instructions() {
    echo ""
    echo -e "${YELLOW}LLM Server Configuration${NC}"
    echo "ZChat needs an LLM server to work. Configure manually:"
    echo ""
    echo "For OpenAI API:"
    echo -e "  ${LIGHT_BLUE}export OPENAI_BASE_URL=https://api.openai.com/v1${NC}"
    echo -e "  ${LIGHT_BLUE}export OPENAI_API_KEY=your-key-here${NC}"
    echo ""
    echo "For local llama.cpp:"
    echo -e "  ${LIGHT_BLUE}export LLAMA_URL=http://localhost:8080${NC}"
    echo ""
    echo "For Ollama:"
    echo -e "  ${LIGHT_BLUE}export OLLAMA_BASE_URL=http://localhost:11434${NC}"
    echo ""
}

# Main execution
main() {
    echo -e "${BLUE}ZChat Unified Installer v0.9${NC}"
    echo ""

    # Check for existing installation (except for repair mode)
    if [ "$INSTALL_MODE" != "repair" ]; then
        check_existing_installation
    fi

    # Execute based on mode
    case "$INSTALL_MODE" in
        "standard")
            install_standard
            ;;
        "minimal")
            install_minimal
            ;;
        "adaptive")
            install_adaptive
            ;;
        "single")
            create_single_executable
            ;;
        "bundle")
            create_static_bundle
            ;;
        "platform")
            create_platform_bundles
            ;;
        "optimized")
            create_optimized_bundle
            ;;
        "repair")
            repair_installation
            ;;
        *)
            print_error "Unknown installation mode: $INSTALL_MODE"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"