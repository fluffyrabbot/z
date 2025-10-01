#!/bin/bash
# ZChat Adaptive Installer v0.8b
# Enhanced adaptive installation with progress bars and validation

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
fi

print_status() { echo -e "${GREEN}[OK]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Parse command line arguments
VERBOSE=false
FORCE=false

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
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Setup logging
setup_logging

# Fallback functions if progress-utils.sh not available
if [ ! -f "./progress-utils.sh" ]; then
    backup_config() {
        local config_file="$1"
        if [ -f "$config_file" ]; then
            local backup="${config_file}.backup.$(date +%s)"
            cp "$config_file" "$backup"
            echo -e "${GREEN}✓ Config backed up to: $backup${NC}"
        fi
    }
    
    post_install_test() {
        echo -e "${BLUE}Running post-installation tests...${NC}"
        local errors=0
        
        # Test z command
        if [ -f "./z" ]; then
            if ./z --help >/dev/null 2>&1; then
                echo -e "${GREEN}✓ ZChat command works${NC}"
            else
                echo -e "${RED}✗ ZChat command failed${NC}"
                ((errors++))
            fi
        fi
        
        # Test Perl modules
        local modules=("Mojo::UserAgent" "JSON::XS" "YAML::XS")
        for module in "${modules[@]}"; do
            if perl -M"$module" -e '1' 2>/dev/null; then
                echo -e "${GREEN}✓ Module $module loads${NC}"
            else
                echo -e "${RED}✗ Module $module failed to load${NC}"
                ((errors++))
            fi
        done
        
        if [ $errors -gt 0 ]; then
            echo -e "${RED}Post-installation tests failed with $errors errors${NC}"
            return 1
        fi
        
        echo -e "${GREEN}✓ All post-installation tests passed${NC}"
        return 0
    }
fi

echo "ZChat Adaptive Installer v0.8b"
echo ""

# Check for existing installation
if [ -f "$HOME/.config/zchat/user.yaml" ] || [ -f "./z" ] || command -v z >/dev/null 2>&1; then
    if [ "$FORCE" = "true" ]; then
        echo -e "${YELLOW}Force flag detected - proceeding with fresh installation...${NC}"
        echo ""
        # Backup existing config
        backup_config "$HOME/.config/zchat/user.yaml"
    else
        echo -e "${YELLOW}Existing ZChat installation detected!${NC}"
        echo ""
        echo "ZChat appears to already be installed on this system."
        echo "To avoid conflicts and preserve your existing setup, please use:"
        echo ""
        echo -e "  ${LIGHT_BLUE}./repair-installation.sh${NC}"
        echo ""
        echo "The repair installer can:"
        echo "  • Fix dependency issues"
        echo "  • Update to the latest version"
        echo "  • Diagnose problems"
        echo "  • Clean uninstall if needed"
        echo ""
        echo "If you want to force a fresh installation anyway, run:"
        echo -e "  ${LIGHT_BLUE}./install-adaptive.sh --force${NC}"
        echo ""
        echo -e "${RED}Exiting to protect existing installation.${NC}"
        echo "Use --force flag to override this protection."
        exit 0
    fi
fi

echo "Automatically detects your environment and adjusts installation accordingly."
echo ""

# Source environment detector
if [ -f "./environment-detector.sh" ]; then
    source ./environment-detector.sh
    detect_environment
else
    print_error "environment-detector.sh not found"
    exit 1
fi

# Determine best installation method based on environment
determine_installation_method() {
    print_info "Determining best installation method..."
    
    # Container environments: Use static bundle
    if [ "$IS_CONTAINER" = "true" ]; then
        INSTALL_METHOD="bundle"
        print_info "Container detected: Using static bundle for portability"
        return
    fi
    
    # WSL environments: Prefer static bundle for reliability
    if [ "$IS_WSL" = "true" ]; then
        INSTALL_METHOD="bundle"
        print_info "WSL detected: Using static bundle for reliability"
        return
    fi
    
    # Unknown package managers: Use static bundle
    if [ "$PACKAGE_MANAGER" = "unknown" ]; then
        INSTALL_METHOD="bundle"
        print_info "Unknown package manager: Using static bundle"
        return
    fi
    
    # No sudo: Use minimal installer with local::lib
    if [ "$HAS_SUDO" = "false" ]; then
        INSTALL_METHOD="minimal"
        print_info "No sudo available: Using minimal installer with local::lib"
        return
    fi
    
    # Root user: Use standard installer
    if [ "$IS_ROOT" = "true" ]; then
        INSTALL_METHOD="standard"
        print_info "Root user: Using standard installer"
        return
    fi
    
    # Default: Use minimal installer for regular users
    INSTALL_METHOD="minimal"
    print_info "Regular user: Using minimal installer"
}

# Install system dependencies
install_system_dependencies() {
    print_info "Installing system dependencies..."
    
    if [ -n "$UPDATE_CMD" ]; then
        print_info "Updating package lists..."
        eval $UPDATE_CMD
    fi
    
    if [ -n "$INSTALL_CMD" ] && [ -n "$BUILD_PACKAGES" ]; then
        print_info "Installing build tools: $BUILD_PACKAGES"
        eval "$INSTALL_CMD $BUILD_PACKAGES"
    else
        print_warning "Cannot install system dependencies automatically"
        print_info "Please install manually:"
        case "$PACKAGE_MANAGER" in
            "apt") echo "  sudo apt-get install build-essential libssl-dev curl wget" ;;
            "yum") echo "  sudo yum install gcc openssl-devel curl wget" ;;
            "pacman") echo "  sudo pacman -S base-devel curl wget" ;;
            "brew") echo "  brew install curl wget" ;;
            *) echo "  Install: gcc, openssl-dev, curl, wget" ;;
        esac
    fi
}

# Install Perl dependencies
install_perl_dependencies() {
    print_info "Installing Perl dependencies..."
    
    # Setup local::lib for user installation
    if [ "$IS_ROOT" = "false" ]; then
        print_info "Setting up local::lib for user installation..."
        if ! perl -e "use local::lib; 1" 2>/dev/null; then
            print_info "Installing local::lib..."
            if [ "$HAS_CURL" = "true" ]; then
                curl -L https://cpanmin.us | perl - --local-lib=~/perl5 local::lib 2>/dev/null
            elif [ "$HAS_WGET" = "true" ]; then
                wget -O - https://cpanmin.us | perl - --local-lib=~/perl5 local::lib 2>/dev/null
            else
                print_error "Neither curl nor wget available for downloading cpanm"
                return 1
            fi
        fi
        
        # Setup environment
        print_info "Configuring Perl environment..."
        if ! eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib); then
            print_error "Failed to configure Perl environment"
            return 1
        fi
    fi
    
    # Install cpanm
    print_info "Installing cpanm..."
    if ! command -v cpanm >/dev/null 2>&1; then
        if [ "$HAS_CURL" = "true" ]; then
            curl -L https://cpanmin.us | perl - App::cpanminus 2>/dev/null
        elif [ "$HAS_WGET" = "true" ]; then
            wget -O - https://cpanmin.us | perl - App::cpanminus 2>/dev/null
        else
            print_error "Cannot install cpanm without curl or wget"
            return 1
        fi
        print_status "cpanm installed"
    else
        print_status "cpanm already installed"
    fi
    
    # Install Perl modules
    print_info "Installing Perl modules..."
    
    # Source dependencies
    if [ -f "./dependencies.sh" ]; then
        source ./dependencies.sh
        modules=($(export_core_modules))
    else
        print_error "dependencies.sh not found"
        return 1
    fi
    
    # Install modules
    for module in "${modules[@]}"; do
        if perl -e "use $module; 1" 2>/dev/null; then
            print_status "$module (already installed)"
        else
            print_info "Installing $module..."
            if cpanm --notest --quiet "$module" 2>/dev/null; then
                print_status "$module installed"
            else
                print_error "Failed to install $module"
                return 1
            fi
        fi
    done
}

# Install ImageMagick if requested
install_imagemagick() {
    if [ "$INSTALL_METHOD" = "standard" ] || [ "$INSTALL_METHOD" = "minimal" ]; then
        print_info "Installing ImageMagick for image processing..."
        
        if [ -n "$INSTALL_CMD" ] && [ -n "$IMAGEMAGICK_PACKAGES" ]; then
            eval "$INSTALL_CMD $IMAGEMAGICK_PACKAGES"
            
            # Install Perl module
            print_info "Installing Image::Magick Perl module..."
            if cpanm --notest --quiet "Image::Magick" 2>/dev/null; then
                print_status "Image::Magick installed"
            else
                print_warning "Image::Magick failed to install (optional)"
            fi
        else
            print_warning "Cannot install ImageMagick automatically"
        fi
    fi
}

# Install ZChat
install_zchat() {
    print_info "Installing ZChat..."
    
    # Make executable
    chmod +x z
    
    # Create configuration directories
    mkdir -p ~/.config/zchat/system
    mkdir -p ~/.config/zchat/sessions
    
    # Create default system prompt
    cat > ~/.config/zchat/system/default << 'EOF'
You are a helpful AI assistant. You provide clear, concise, and accurate responses.

You understand that this is a command-line interface, so you should:
- Be direct and practical in your responses
- Provide code examples when relevant
- Explain technical concepts clearly
- Focus on actionable advice
EOF
    
    # Create user config if it doesn't exist
    if [ ! -f ~/.config/zchat/user.yaml ]; then
        cat > ~/.config/zchat/user.yaml << 'EOF'
# ZChat User Configuration
# This file stores your global preferences

session: "default"
system_string: "You are a helpful AI assistant."

# Pin configuration
pin_limits:
  system: 50
  user: 50
  assistant: 50

# Pin modes (see help/pins.md for details)
pin_mode_sys: "vars"      # vars|concat|both
pin_mode_user: "concat"   # vars|varsfirst|concat
pin_mode_ast: "concat"    # vars|varsfirst|concat
EOF
    fi
    
    # Create initial session
    mkdir -p ~/.config/zchat/sessions/default
    cat > ~/.config/zchat/sessions/default/session.yaml << 'EOF'
created: 1703123456
# Session-specific settings go here
EOF
    
    print_status "ZChat installed successfully"
}

# Setup PATH
setup_path() {
    print_info "Setting up PATH..."
    
    # Define install prefix
    INSTALL_PREFIX="$HOME/.local"
    
    # Add to PATH for current session
    export PATH="$INSTALL_PREFIX/bin:$PATH"
    
    # Check if already in shell config
    if [ -f ~/.bashrc ] && ! grep -q "ZChat" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# ZChat PATH configuration" >> ~/.bashrc
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ~/.bashrc
        print_status "Added ZChat to ~/.bashrc"
    fi
    
    if [ -f ~/.zshrc ] && ! grep -q "ZChat" ~/.zshrc; then
        echo "" >> ~/.zshrc
        echo "# ZChat PATH configuration" >> ~/.zshrc
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ~/.zshrc
        print_status "Added ZChat to ~/.zshrc"
    fi
}

# Test installation
test_installation() {
    print_info "Testing installation..."
    
    if ./z --status >/dev/null 2>&1; then
        print_status "ZChat is working correctly"
    else
        print_warning "ZChat installed but may need LLM server configuration"
    fi
}

# Configure API (optional)
configure_api_if_available() {
    if [ -f "./api-config.sh" ]; then
        source ./api-config.sh
        configure_api
        test_api_config
    else
        echo ""
        print_info "LLM Server Configuration"
        echo "ZChat needs an LLM server to work. Configure manually:"
        echo ""
        echo "For OpenAI API:"
        echo "  export OPENAI_BASE_URL=https://api.openai.com/v1"
        echo "  export OPENAI_API_KEY=your-key-here"
        echo ""
        echo "For local llama.cpp:"
        echo "  export LLAMA_URL=http://localhost:8080"
        echo ""
        echo "For Ollama:"
        echo "  export OLLAMA_BASE_URL=http://localhost:11434"
        echo ""
    fi
}

# Main installation process
main() {
    # Determine installation method
    determine_installation_method
    
    echo ""
    print_info "Selected installation method: $INSTALL_METHOD"
    echo ""
    
    # Install based on method
    case "$INSTALL_METHOD" in
        "bundle")
            print_info "Using static bundle installation..."
            if [ -f "./create-bundle.sh" ]; then
                ./create-bundle.sh
            else
                print_error "create-bundle.sh not found"
                exit 1
            fi
            ;;
        "standard")
            print_info "Using standard installation..."
            install_system_dependencies
            install_perl_dependencies
            install_imagemagick
            install_zchat
            setup_path
            test_installation
            configure_api_if_available
            ;;
        "minimal")
            print_info "Using minimal installation..."
            install_system_dependencies
            install_perl_dependencies
            install_zchat
            setup_path
            test_installation
            configure_api_if_available
            ;;
        *)
            print_error "Unknown installation method: $INSTALL_METHOD"
            exit 1
            ;;
    esac
    
    echo ""
    print_status "Installation completed successfully!"
    
    # Run post-installation tests
    echo ""
    print_info "Running post-installation tests..."
    if post_install_test; then
        print_status "✓ All tests passed!"
    else
        print_warning "⚠ Some tests failed, but installation may still work"
    fi
    
    echo ""
    echo "Environment-specific notes:"
    
    if [ "$IS_WSL" = "true" ]; then
        echo "  - WSL detected: Consider using Windows-native Perl for better performance"
    fi
    
    if [ "$IS_CONTAINER" = "true" ]; then
        echo "  - Container detected: Static bundle provides maximum portability"
    fi
    
    if [ "$HAS_SUDO" = "false" ]; then
        echo "  - No sudo: All dependencies installed to user directory"
    fi
    
    echo ""
    echo "Quick start:"
    echo -e "  ${LIGHT_BLUE}z --help${NC}                    # Full help"
    echo -e "  ${LIGHT_BLUE}z --status${NC}                  # View configuration"
    echo -e "  ${LIGHT_BLUE}z 'Hello, how are you?'${NC}     # Simple query"
    echo ""
    echo "LLM Server Setup:"
    echo -e "  ${LIGHT_BLUE}export OPENAI_API_KEY=your-key-here${NC}"
    echo -e "  ${LIGHT_BLUE}export LLAMA_URL=http://localhost:8080${NC}"
    echo -e "  ${LIGHT_BLUE}export OLLAMA_BASE_URL=http://localhost:11434${NC}"
}

# Run main function
main "$@"