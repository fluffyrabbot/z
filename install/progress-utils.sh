#!/bin/bash
# ZChat Progress Utilities v0.8b
# Enhanced progress indicators and user feedback

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
LIGHT_BLUE='\033[0;36m'
NC='\033[0m'

# Progress bar with Unicode characters
show_progress_bar() {
    local current=$1
    local total=$2
    local desc=$3
    local start_time=${4:-$(date +%s)}
    local width=50
    
    local percent=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    # Calculate ETA if we have start time
    local eta=""
    if [ $current -gt 0 ] && [ $start_time -gt 0 ]; then
        local elapsed=$(($(date +%s) - start_time))
        local eta_seconds=$((elapsed * (total - current) / current))
        eta=" ETA: ${eta_seconds}s"
    fi
    
    printf "\r[%3d%%] [" $percent
    printf "%*s" $filled | tr ' ' '█'
    printf "%*s" $empty | tr ' ' '░'
    printf "] %s (%d/%d)%s" "$desc" $current $total "$eta"
}

# Spinner for indeterminate operations
show_spinner() {
    local pid=$1
    local desc=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        printf "\r${spin:$((i % 10)):1} %s" "$desc"
        sleep 0.1
        ((i++))
    done
    printf "\r✓ %s\n" "$desc"
}

# Enhanced progress with success/failure indicators
show_enhanced_progress() {
    local current=$1
    local total=$2
    local desc=$3
    local status=$4  # "working", "success", "failed"
    local start_time=${5:-$(date +%s)}
    
    case $status in
        "working")
            show_progress_bar $current $total "$desc" $start_time
            ;;
        "success")
            printf "\r✓ %s\n" "$desc"
            ;;
        "failed")
            printf "\r✗ %s\n" "$desc"
            ;;
    esac
}

# Retry logic with exponential backoff
retry_operation() {
    local max_attempts=$1
    local delay=$2
    local operation="$3"
    local desc="$4"
    
    local attempt=1
    local current_delay=$delay
    
    while [ $attempt -le $max_attempts ]; do
        if [ $attempt -gt 1 ]; then
            echo -e "${YELLOW}Retry attempt $attempt/$max_attempts for: $desc${NC}"
            sleep $current_delay
            current_delay=$((current_delay * 2))  # Exponential backoff
        fi
        
        if eval "$operation"; then
            echo -e "${GREEN}✓ Success: $desc${NC}"
            return 0
        else
            echo -e "${RED}✗ Failed attempt $attempt: $desc${NC}"
            ((attempt++))
        fi
    done
    
    echo -e "${RED}✗ All attempts failed: $desc${NC}"
    return 1
}

# Pre-flight system checks
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

# Post-installation testing
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

# Interactive dependency selection
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

# Configuration management
backup_config() {
    local config_file="$1"
    if [ -f "$config_file" ]; then
        local backup="${config_file}.backup.$(date +%s)"
        cp "$config_file" "$backup"
        echo -e "${GREEN}✓ Config backed up to: $backup${NC}"
    fi
}

# Detect shell and add to appropriate config file
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

# Logging utilities
setup_logging() {
    local log_dir="$HOME/.zchat"
    local log_file="$log_dir/install.log"
    
    mkdir -p "$log_dir"
    
    # Log function
    log() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$log_file"
    }
    
    echo "Logging to: $log_file"
    log "Installation started"
}

# Verbose mode handler
verbose_echo() {
    if [ "$VERBOSE" = "true" ]; then
        echo "$1"
    fi
}

# Export functions for use in other scripts
export -f show_progress_bar
export -f show_spinner
export -f show_enhanced_progress
export -f retry_operation
export -f preflight_checks
export -f post_install_test
export -f select_dependencies
export -f backup_config
export -f detect_and_configure_shell
export -f setup_logging
export -f verbose_echo