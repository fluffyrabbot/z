#!/bin/bash
# Minimal ZChat Dependency Installer v0.8b
# Enhanced installer with progress bars, retry logic, and validation

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
OFFLINE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE=true
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

# Check if module is installed
check_module() {
    perl -e "use $1; 1" 2>/dev/null
}

echo "ZChat Dependency Installer"
echo "=========================="
echo ""
echo "This installer can install dependencies at different levels:"
echo ""
echo -e "${LIGHT_BLUE}1. Minimal (Recommended)${NC}"
echo "   - All core dependencies (Mojo::UserAgent, JSON::XS, YAML::XS, Text::Xslate, Clipboard, etc.)"
echo "   - Fast installation, works for most users"
echo "   - Image processing will be disabled"
echo ""
echo -e "${LIGHT_BLUE}2. Complete${NC}"
echo "   - All dependencies including Image::Magick"
echo "   - Enables image processing features (--img, --clipboard with images)"
echo "   - May take longer and could fail on some systems"
echo ""
echo -e "${LIGHT_BLUE}3. Skip Dependencies${NC}"
echo "   - Only install system build tools"
echo "   - Install Perl modules manually later"
echo ""
read -p "Choose installation level (1-3): " -r
echo ""

case $REPLY in
    1)
        INSTALL_LEVEL="minimal"
        print_info "Selected: Minimal installation"
        ;;
    2)
        INSTALL_LEVEL="complete"
        print_info "Selected: Complete installation"
        ;;
    3)
        INSTALL_LEVEL="skip"
        print_info "Selected: Skip Perl dependencies"
        ;;
    *)
        INSTALL_LEVEL="minimal"
        print_info "Invalid choice, defaulting to minimal installation"
        ;;
esac

echo ""

# Check Perl version
print_info "Checking Perl version..."
if perl -e 'use v5.26.3; 1' 2>/dev/null; then
    print_status "Perl version OK"
else
    print_error "Perl version too old. ZChat requires Perl 5.26.3 or later."
    exit 1
fi

# Install build tools
print_info "Installing build tools..."
if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -qq
    sudo apt-get install -y build-essential libssl-dev curl wget
elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y gcc openssl-devel curl wget
elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --noconfirm base-devel curl wget
fi

# Setup local::lib for user installation
print_info "Setting up local::lib for user installation..."
if ! perl -e "use local::lib; 1" 2>/dev/null; then
    print_info "Installing local::lib..."
    curl -L https://cpanmin.us | perl - --local-lib=~/perl5 local::lib 2>/dev/null
fi

# Setup environment
print_info "Configuring Perl environment..."
eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)

# Install cpanm
print_info "Installing cpanm..."
if ! command -v cpanm >/dev/null 2>&1; then
    curl -L https://cpanmin.us | perl - App::cpanminus 2>/dev/null
    print_status "cpanm installed"
else
    print_status "cpanm already installed"
fi

# Install Perl modules based on installation level
if [ "$INSTALL_LEVEL" = "skip" ]; then
    print_info "Skipping Perl module installation"
    print_info "You can install them manually later with:"
    print_info "  eval \$(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)"
    print_info "  cpanm Mojo::UserAgent JSON::XS YAML::XS Text::Xslate Clipboard Getopt::Long::Descriptive URI::Escape Data::Dumper String::ShellQuote File::Slurper File::Copy File::Temp File::Compare Carp Term::ReadLine Term::ReadLine::Gnu Capture::Tiny LWP::UserAgent Term::Size"
    exit 0
fi

# Define modules based on installation level
if [ -f "./dependencies.sh" ]; then
    source ./dependencies.sh
    if [ "$INSTALL_LEVEL" = "minimal" ]; then
        modules=($(export_core_modules))
    else
        modules=($(export_all_modules))
    fi
else
    print_error "dependencies.sh not found"
    exit 1
fi

missing_modules=()

print_info "Checking required modules..."
for module in "${modules[@]}"; do
    if check_module "$module"; then
        print_status "$module"
    else
        print_info "$module missing"
        missing_modules+=("$module")
    fi
done

if [ ${#missing_modules[@]} -eq 0 ]; then
    print_status "All modules already installed!"
    exit 0
fi

print_info "Installing missing modules: ${missing_modules[*]}"

# Install system dependencies for Image::Magick first
if [[ " ${missing_modules[@]} " =~ " Image::Magick " ]]; then
    print_info "Installing ImageMagick system library..."
    if command -v apt-get >/dev/null 2>&1; then
        # Try ImageMagick 7 first, fallback to 6
        if sudo apt-get install -y libmagick++-7-dev libmagickcore-7-dev libmagickwand-7-dev 2>/dev/null; then
            print_status "ImageMagick 7 development libraries installed"
        else
            print_warning "ImageMagick 7 not available, installing ImageMagick 6"
            sudo apt-get install -y libmagickwand-dev imagemagick
        fi
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y ImageMagick-devel ImageMagick
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm imagemagick
    fi
fi

total_modules=${#missing_modules[@]}
current_module=0
start_time=$(date +%s)

for module in "${missing_modules[@]}"; do
    current_module=$((current_module + 1))
    show_progress_bar $current_module $total_modules "Installing $module" $start_time
    
    # Special handling for Image::Magick
    if [ "$module" = "Image::Magick" ]; then
        # Force ImageMagick 6 compatibility
        verbose_echo "Configuring Image::Magick for ImageMagick 6..."
        
        # Find cpanm in the right location
        CPANM_CMD="cpanm"
        if [ -f "$HOME/perl5/bin/cpanm" ]; then
            CPANM_CMD="$HOME/perl5/bin/cpanm"
        elif [ -f "/usr/local/bin/cpanm" ]; then
            CPANM_CMD="/usr/local/bin/cpanm"
        fi
        
        # Use retry logic for Image::Magick
        if retry_operation 3 2 "MAGICK_HOME=/usr/include/ImageMagick-6 $CPANM_CMD --notest --quiet $module 2>/dev/null" "Image::Magick installation"; then
            show_enhanced_progress $current_module $total_modules "$module" "success" $start_time
        else
            show_enhanced_progress $current_module $total_modules "$module" "failed" $start_time
            print_warning "$module failed to install via CPAN"
            print_info "This is optional - ZChat will work without image processing"
            print_info "Manual installation:"
            print_info "  eval \$(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)"
            print_info "  export MAGICK_HOME=/usr/include/ImageMagick-6"
            print_info "  cpanm Image::Magick"
        fi
    else
        # Find cpanm in the right location
        CPANM_CMD="cpanm"
        if [ -f "$HOME/perl5/bin/cpanm" ]; then
            CPANM_CMD="$HOME/perl5/bin/cpanm"
        elif [ -f "/usr/local/bin/cpanm" ]; then
            CPANM_CMD="/usr/local/bin/cpanm"
        fi
        
        # Use retry logic for other modules
        if retry_operation 3 2 "$CPANM_CMD --notest --quiet $module 2>/dev/null" "$module installation"; then
            show_enhanced_progress $current_module $total_modules "$module" "success" $start_time
        else
            show_enhanced_progress $current_module $total_modules "$module" "failed" $start_time
            print_error "Failed to install $module after retries"
            exit 1
        fi
    fi
done

echo ""  # Final newline after all progress

# Final verification
print_info "Verifying installation..."
all_good=true
critical_modules=($(export_critical_modules))
optional_modules=($(export_optional_modules))

for module in "${critical_modules[@]}"; do
    if check_module "$module"; then
        print_status "$module"
    else
        print_error "$module"
        all_good=false
    fi
done

for module in "${optional_modules[@]}"; do
    if check_module "$module"; then
        print_status "$module"
    else
        print_warning "$module (optional)"
    fi
done

if [ "$all_good" = true ]; then
    echo ""
    print_status "All critical dependencies installed successfully!"
    echo ""
    print_info "To use ZChat, you may need to run:"
    print_info "  eval \$(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)"
    print_info "Or add this to your ~/.bashrc:"
    print_info "  eval \$(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)"
    
    # Configure API (optional)
    if [ -f "./api-config.sh" ] || [ -f "../api-config.sh" ]; then
        echo ""
        if [ -f "./api-config.sh" ]; then
            source ./api-config.sh
        else
            source ../api-config.sh
        fi
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
else
    echo ""
    print_error "Some critical dependencies failed to install"
    exit 1
fi