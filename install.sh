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
INSTALL_MODE="standard"  # standard, minimal, adaptive, single, platform, optimized, repair

# Check for help first
for arg in "$@"; do
    if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
        # Show help without initializing (to avoid side effects)
        echo "ZChat Unified Installer v0.9"
        echo ""
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Installation Modes:"
        echo "  --minimal         Quick installation with core dependencies only"
        echo "  --adaptive        Smart installation with environment detection"
        echo "  --single          Create single executable (PAR Packer)"
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
        echo "  $0                    # Standard installation"
        echo "  $0 --minimal          # Minimal installation"
        echo "  $0 --adaptive --verbose # Smart installation with verbose output"
        echo "  $0 --repair           # Repair existing installation"
        echo "  $0 --single           # Create single executable"
        echo "  $0 --platform         # Create platform-specific bundles"
        echo "  $0 --optimized        # Create size-optimized bundle"
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
    echo "  --minimal         Quick installation with core dependencies only"
    echo "  --adaptive        Smart installation with environment detection"
    echo "  --single          Create single executable (PAR Packer)"
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
    echo "  $0                    # Standard installation"
    echo "  $0 --minimal          # Minimal installation"
    echo "  $0 --adaptive --verbose # Smart installation with verbose output"
    echo "  $0 --repair           # Repair existing installation"
    echo "  $0 --single           # Create single executable"
    echo "  $0 --platform         # Create platform-specific bundles"
    echo "  $0 --optimized        # Create size-optimized bundle"
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
    if [ -f "$HOME/.config/zchat/user.yaml" ] || [ -f "./z" ] || command -v z >/dev/null 2>&1; then
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
        install_optional=$?
        echo ""
    fi

    # Install dependencies
    print_info "Installing Perl dependencies..."
    echo ""
    
    if [ "$install_optional" = "0" ]; then
        modules=($(export_all_modules))
    else
        modules=($(export_core_modules))
    fi
    
    if ! install_missing_modules "${modules[@]}"; then
        print_error "Dependency installation failed."
        exit 1
    fi

    # Make executable
    make_z_executable

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

    # Install only core dependencies
    print_info "Installing core dependencies only..."
    modules=($(export_core_modules))
    
    if ! install_missing_modules "${modules[@]}"; then
        print_error "Core dependency installation failed."
        exit 1
    fi

    # Make executable
    make_z_executable

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

# Single executable creation
create_single_executable() {
    print_info "Creating single executable..."
    
    if [ -f "./install/create-single-executable.sh" ]; then
        source ./install/create-single-executable.sh
        main  # Call the main function from create-single-executable.sh
    else
        print_error "Single executable creator not found"
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