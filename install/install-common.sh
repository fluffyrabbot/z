#!/bin/bash
# ZChat Installation Common Utilities v0.9
# Shared functionality for all installers

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
LIGHT_BLUE='\033[0;36m'
NC='\033[0m'

# Print functions
print_status() { echo -e "${GREEN}[OK]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Global variables
VERBOSE=false
FORCE=false
OFFLINE=false
INSTALL_OPTIONAL=false

# Parse common command line arguments
parse_common_args() {
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
                # Unknown option - let caller handle it
                return 1
                ;;
        esac
    done
    return 0
}

# Setup logging
setup_logging() {
    local log_dir="$HOME/.zchat"
    local log_file="$log_dir/install.log"
    
    mkdir -p "$log_dir"
    if [ "$VERBOSE" = "true" ]; then
        echo "Logging to: $log_file"
    fi
}

# Source progress utilities with fallback
source_progress_utils() {
    if [ -f "./progress-utils.sh" ]; then
        source ./progress-utils.sh
    elif [ -f "./install/progress-utils.sh" ]; then
        source ./install/progress-utils.sh
    else
        echo "Warning: progress-utils.sh not found, using basic progress"
        # Basic fallback functions
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
            echo "  • xclip - Copy/paste integration (WSL2/Linux)"
            echo "  • Text::Xslate - Template engine"
            echo ""
            
            read -p "Install optional dependencies? (y/N): " install_optional
            case $install_optional in
                [Yy]*)
                    echo "Installing core + optional dependencies"
                    INSTALL_OPTIONAL=true
                    ;;
                *)
                    echo "Installing core dependencies only"
                    INSTALL_OPTIONAL=false
                    ;;
            esac
            return 0
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
    fi
}

# Initialize common functionality
init_installer() {
    source_progress_utils
    setup_logging
}

# Dependency management
export_core_modules() {
    echo "Mojo::UserAgent JSON::XS YAML::XS Getopt::Long::Descriptive URI::Escape Data::Dumper String::ShellQuote File::Slurper File::Copy File::Temp File::Compare Carp Term::ReadLine Capture::Tiny LWP::UserAgent"
}

export_optional_modules() {
    echo "Image::Magick Text::Xslate Term::ReadLine::Gnu Term::Size"
}

# Install system dependencies
install_system_dependencies() {
    print_info "Installing system dependencies..."
    
    # Use enhanced platform dependency system if available
    if [ -f "./install/platform-dependencies.sh" ]; then
        source ./install/platform-dependencies.sh
        install_platform_dependencies
    else
        # Fallback to basic system dependency installation
        install_basic_system_dependencies
    fi
}

# Basic system dependency installation (fallback)
install_basic_system_dependencies() {
    print_info "Installing basic system dependencies..."
    
    # Check if we're on a Debian-based system
    if command -v apt-get >/dev/null 2>&1; then
        print_info "Installing xclip for clipboard support..."
        if ! command -v xclip >/dev/null 2>&1; then
            if sudo apt-get update && sudo apt-get install -y xclip; then
                print_status "✓ xclip installed successfully"
            else
                print_warning "⚠ Failed to install xclip - clipboard functionality may not work"
                print_info "You can install it manually with: sudo apt-get install xclip"
            fi
        else
            print_status "✓ xclip already installed"
        fi
    else
        print_warning "⚠ Cannot install xclip automatically on this system"
        print_info "Please install xclip manually for clipboard support:"
        print_info "  • Ubuntu/Debian: sudo apt-get install xclip"
        print_info "  • CentOS/RHEL: sudo yum install xclip"
        print_info "  • macOS: brew install xclip"
    fi
}

export_all_modules() {
    echo "$(export_core_modules) $(export_optional_modules)"
}

# Check if module is installed
check_module() {
    local module="$1"
    perl -e "use $module; 1" 2>/dev/null
}

# Install missing modules
install_missing_modules() {
    local modules=("$@")
    local missing_modules=()
    local optional_modules=("Image::Magick" "Text::Xslate" "Term::ReadLine::Gnu" "Term::Size")  # Modules that are optional and failures shouldn't be fatal
    
    # Check which modules are missing
    print_info "Checking for missing modules..."
    local total_modules=${#modules[@]}
    local current_module=0
    local start_time=$(date +%s)
    
    for module in "${modules[@]}"; do
        current_module=$((current_module + 1))
        
        if check_module "$module"; then
            show_enhanced_progress $current_module $total_modules "$module (already installed)" "success" $start_time
        else
            missing_modules+=("$module")
            show_enhanced_progress $current_module $total_modules "$module (missing)" "failed" $start_time
        fi
    done
    
    if [ ${#missing_modules[@]} -eq 0 ]; then
        print_status "All required modules are already installed"
        return 0
    fi
    
    print_info "Installing ${#missing_modules[@]} missing modules..."
    echo ""
    
    # Install modules using cpanm with progress bars
    if command -v cpanm >/dev/null 2>&1; then
        local install_total=${#missing_modules[@]}
        local install_current=0
        local install_start_time=$(date +%s)
        
        local failed_modules=()
        for module in "${missing_modules[@]}"; do
            install_current=$((install_current + 1))
            
            # Show progress bar even for single items
            show_progress_bar $install_current $install_total "Installing $module" $install_start_time
            
            if cpanm --notest --quiet "$module" 2>/dev/null; then
                show_enhanced_progress $install_current $install_total "$module" "success" $install_start_time
            else
                show_enhanced_progress $install_current $install_total "$module" "failed" $install_start_time
                
                # Check if this is an optional module
                local is_optional=false
                for optional in "${optional_modules[@]}"; do
                    if [ "$module" = "$optional" ]; then
                        is_optional=true
                        break
                    fi
                done
                
                if [ "$is_optional" = true ]; then
                    print_warning "Failed to install optional module: $module"
                    print_info "This is non-fatal - image processing features will be disabled"
                else
                    print_error "Failed to install required module: $module"
                    failed_modules+=("$module")
                fi
            fi
        done
        
        # Only return failure if required modules failed
        if [ ${#failed_modules[@]} -gt 0 ]; then
            print_error "Required modules failed to install: ${failed_modules[*]}"
            return 1
        fi
        
        print_status "Module installation completed!"
    else
        print_error "cpanm not found. Please install App::cpanminus first:"
        echo "curl -L https://cpanmin.us | perl - App::cpanminus"
        return 1
    fi
    
    return 0
}

# Create default configuration
create_default_config() {
    # Create initial configuration
    print_info "Setting up initial configuration..."
    
    # Determine platform-sensitive config directory
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
    
    # Define configuration steps
    local config_steps=(
        "Creating system directories"
        "Creating default system prompt"
        "Creating user configuration"
        "Creating initial session"
    )
    
    local total_steps=${#config_steps[@]}
    local current_step=0
    local start_time=$(date +%s)
    
    # Step 1: Create directories
    current_step=$((current_step + 1))
    show_progress_bar $current_step $total_steps "${config_steps[0]}" $start_time
    
    mkdir -p "$config_dir/system"
    mkdir -p "$config_dir/sessions"
    show_enhanced_progress $current_step $total_steps "${config_steps[0]}" "success" $start_time

    # Step 2: Create default system prompt
    current_step=$((current_step + 1))
    show_progress_bar $current_step $total_steps "${config_steps[1]}" $start_time
    
    cat > "$config_dir/system/default" << 'EOF'
You are a helpful AI assistant. You provide clear, concise, and accurate responses.

You understand that this is a command-line interface, so you should:
- Be direct and practical in your responses
- Provide code examples when relevant
- Explain technical concepts clearly
- Focus on actionable advice
EOF
    show_enhanced_progress $current_step $total_steps "${config_steps[1]}" "success" $start_time

    # Step 3: Create user config if it doesn't exist
    current_step=$((current_step + 1))
    show_progress_bar $current_step $total_steps "${config_steps[2]}" $start_time
    
    if [ ! -f "$config_dir/user.yaml" ]; then
        cat > "$config_dir/user.yaml" << 'EOF'
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
    show_enhanced_progress $current_step $total_steps "${config_steps[2]}" "success" $start_time

    # Step 4: Create initial session
    current_step=$((current_step + 1))
    show_progress_bar $current_step $total_steps "${config_steps[3]}" $start_time
    
    mkdir -p "$config_dir/sessions/default"
    cat > "$config_dir/sessions/default/session.yaml" << 'EOF'
created: 1703123456
# Session-specific settings go here
EOF
    show_enhanced_progress $current_step $total_steps "${config_steps[3]}" "success" $start_time

    print_status "Configuration created"
}

# Make z executable
make_z_executable() {
    if [ -f "./z" ]; then
        chmod +x z
        print_status "Made z executable"
    else
        print_error "z script not found"
        return 1
    fi
}

# Show installation completion message
show_completion_message() {
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
    echo -e "${YELLOW}Important:${NC}"
    echo -e "  ${LIGHT_BLUE}Start a new bash session${NC} to use the 'z' command"
    echo -e "  ${LIGHT_BLUE}Or run: source ~/.bashrc${NC} to reload your shell"
    echo ""
    echo "For more information, see the README.md file."
}