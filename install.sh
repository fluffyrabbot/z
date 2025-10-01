#!/bin/bash
# ZChat Installation Script v0.8b
# Enhanced installation with progress bars, retry logic, and validation

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
    
    preflight_checks() {
        echo -e "${BLUE}Running pre-flight checks...${NC}"
        local errors=0
        
        # Check Perl version
        if ! perl -e 'exit($] < 5.026003 ? 1 : 0)' 2>/dev/null; then
            echo -e "${RED}✗ Perl version too old (need 5.26.3+)${NC}"
            ((errors++))
        else
            echo -e "${GREEN}✓ Perl version OK${NC}"
        fi
        
        # Check internet connectivity
        if ! ping -c 1 cpan.org >/dev/null 2>&1; then
            echo -e "${YELLOW}⚠ No internet connection to CPAN${NC}"
        else
            echo -e "${GREEN}✓ Internet connectivity OK${NC}"
        fi
        
        # Check disk space (need at least 100MB)
        local available=$(df . | awk 'NR==2 {print $4}')
        if [ $available -lt 102400 ]; then
            echo -e "${RED}✗ Insufficient disk space (need 100MB+)${NC}"
            ((errors++))
        else
            echo -e "${GREEN}✓ Disk space OK${NC}"
        fi
        
        # Check write permissions
        if [ ! -w . ]; then
            echo -e "${RED}✗ No write permission in current directory${NC}"
            ((errors++))
        else
            echo -e "${GREEN}✓ Write permissions OK${NC}"
        fi
        
        if [ $errors -gt 0 ]; then
            echo -e "${RED}Pre-flight checks failed with $errors errors${NC}"
            return 1
        fi
        
        echo -e "${GREEN}✓ All pre-flight checks passed${NC}"
        return 0
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
    
    select_dependencies() {
        echo -e "${BLUE}Dependency Selection${NC}"
        echo ""
        echo "Core dependencies (required):"
        echo "  • Mojo::UserAgent - HTTP client"
        echo "  • JSON::XS - JSON parsing"
        echo "  • YAML::XS - Configuration files"
        echo ""
        echo "Optional dependencies:"
        echo "  • Image::Magick - Image processing (multi-modal LLM)"
        echo "  • Clipboard - Copy/paste integration"
        echo "  • Text::Xslate - Template engine"
        echo ""
        
        read -p "Install optional dependencies? (y/N): " install_optional
        case $install_optional in
            [Yy]*)
                echo "Installing core + optional dependencies"
                return 0
                ;;
            *)
                echo "Installing core dependencies only"
                return 1
                ;;
        esac
    }
    
    backup_config() {
        local config_file="$1"
        if [ -f "$config_file" ]; then
            local backup="${config_file}.backup.$(date +%s)"
            cp "$config_file" "$backup"
            echo -e "${GREEN}✓ Config backed up to: $backup${NC}"
        fi
    }
    
    detect_and_configure_shell() {
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
        
        echo "Detected shell: $SHELL"
        echo "Config file: $shell_config"
        
        if [ -f "$shell_config" ]; then
            echo -e "${GREEN}✓ Shell config file found${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠ Shell config file not found${NC}"
            return 1
        fi
    }
    
    setup_logging() {
        local log_dir="$HOME/.zchat"
        local log_file="$log_dir/install.log"
        
        mkdir -p "$log_dir"
        echo "Logging to: $log_file"
    }
fi

# Parse command line arguments
VERBOSE=false
FORCE=false
OFFLINE=false

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
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Setup logging
setup_logging

echo -e "${BLUE}ZChat Installation${NC}"
echo ""

# Run pre-flight checks
if ! preflight_checks; then
    echo -e "${RED}Pre-flight checks failed. Aborting installation.${NC}"
    exit 1
fi
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
        echo -e "  ${LIGHT_BLUE}./install.sh --force${NC}"
        echo ""
        echo -e "${RED}Exiting to protect existing installation.${NC}"
        echo "Use --force flag to override this protection."
        exit 0
    fi
fi

# Interactive dependency selection
if [ "$OFFLINE" = "false" ]; then
    echo -e "${BLUE}Dependency Selection${NC}"
    echo ""
    select_dependencies
    install_optional=$?
    echo ""
fi

# Install dependencies with enhanced progress
echo -e "${YELLOW}Installing Perl dependencies...${NC}"
echo ""

# Check if we have a dedicated dependency installer
if [ -f "./install-deps-minimal.sh" ]; then
    echo "Using minimal dependency installer..."
    if [ "$VERBOSE" = "true" ]; then
        ./install-deps-minimal.sh --verbose
    else
        ./install-deps-minimal.sh
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Dependencies installed successfully!${NC}"
    else
        echo -e "${RED}Dependency installation failed.${NC}"
        echo "You can try running ./install-deps-minimal.sh manually for more detailed output."
        exit 1
    fi
else
    echo -e "${YELLOW}WARNING: install-deps-minimal.sh not found. Using fallback method.${NC}"
    
    # Fallback: simple module check and install
    if [ -f "./dependencies.sh" ]; then
        source ./dependencies.sh
        modules=($(export_core_modules))
    else
        modules=("Mojo::UserAgent" "JSON::XS" "YAML::XS" "Text::Xslate" "Clipboard" "Getopt::Long::Descriptive" "URI::Escape" "Data::Dumper" "String::ShellQuote" "File::Slurper" "File::Copy" "File::Temp" "File::Compare" "Carp" "Term::ReadLine" "Term::ReadLine::Gnu" "Capture::Tiny" "LWP::UserAgent" "Term::Size")
    fi
    missing_modules=()
    
    for module in "${modules[@]}"; do
        if perl -e "use $module; 1" 2>/dev/null; then
            echo -e "${GREEN}OK: $module${NC}"
        else
            echo -e "${RED}MISSING: $module${NC}"
            missing_modules+=("$module")
        fi
    done
    
    if [ ${#missing_modules[@]} -gt 0 ]; then
        echo ""
        echo -e "${RED}ERROR: Missing modules: ${missing_modules[*]}${NC}"
        echo ""
        echo "Please install dependencies manually:"
        echo ""
        echo "1. Try the minimal installer: ./install-deps-minimal.sh"
        echo ""
        echo "2. Install system build tools first:"
        echo "   Debian/Ubuntu: sudo apt-get install build-essential libssl-dev curl wget"
        echo "   RedHat/CentOS: sudo yum install gcc openssl-devel curl wget"
        echo "   Arch Linux: sudo pacman -S base-devel curl wget"
        echo ""
        echo "3. Install Perl modules with cpanm:"
        echo "   curl -L https://cpanmin.us | perl - App::cpanminus"
        echo "   eval \$(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)"
        echo "   cpanm ${missing_modules[*]}"
        echo ""
        echo "4. Or install all at once:"
        echo "   cpanm Mojo::UserAgent JSON::XS YAML::XS Text::Xslate Clipboard Getopt::Long::Descriptive URI::Escape Data::Dumper String::ShellQuote File::Slurper File::Copy File::Temp File::Compare Carp Term::ReadLine Term::ReadLine::Gnu Capture::Tiny LWP::UserAgent Term::Size"
        exit 1
    fi
fi

# Make executable
if [ -f "./z" ]; then
    chmod +x z
else
    echo -e "${RED}ERROR: z script not found${NC}"
    exit 1
fi

# Create initial configuration
echo -e "${YELLOW}Setting up initial configuration...${NC}"
mkdir -p ~/.config/zchat/system
mkdir -p ~/.config/zchat/sessions

# Create default system prompt (matching author's style)
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

echo -e "${GREEN}OK: Configuration created${NC}"

# Detect and configure shell
echo -e "${YELLOW}Configuring shell integration...${NC}"
if detect_and_configure_shell; then
    echo -e "${GREEN}✓ Shell configuration detected${NC}"
else
    echo -e "${YELLOW}⚠ Shell configuration not found${NC}"
fi

# Run post-installation tests
echo -e "${YELLOW}Running post-installation tests...${NC}"
if post_install_test; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
else
    echo -e "${YELLOW}⚠ Some tests failed, but installation may still work${NC}"
fi
echo ""

# Configure API (optional)
if [ -f "./api-config.sh" ]; then
    source ./api-config.sh
    configure_api
    test_api_config
else
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
fi

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Quick start:"
echo -e "  ${LIGHT_BLUE}z 'Hello, how are you?'${NC}     # Simple query"
echo -e "  ${LIGHT_BLUE}z -i${NC}                        # Interactive mode"
echo -e "  ${LIGHT_BLUE}z --status${NC}                  # View configuration"
echo -e "  ${LIGHT_BLUE}z --help${NC}                    # Full help"
echo ""
echo "Configuration:"
echo -e "  ${LIGHT_BLUE}z --help-cli${NC}                # CLI usage guide"
echo -e "  ${LIGHT_BLUE}z --help-pins${NC}               # Pin system documentation"
echo ""
echo "LLM Server Setup:"
echo -e "  ${LIGHT_BLUE}export LLAMA_URL=http://localhost:8080${NC}  # Local llama.cpp"
echo -e "  ${LIGHT_BLUE}export OPENAI_BASE_URL=https://api.openai.com/v1${NC}  # OpenAI"
echo -e "  ${LIGHT_BLUE}export OPENAI_API_KEY=your-key-here${NC}"
echo ""
echo "For more information, see the README.md file."