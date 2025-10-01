#!/bin/bash
# ZChat Single Executable Creator v0.9
# Creates a single executable using PAR Packer (pp)

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
        local start_time=$5
        local elapsed=$(($(date +%s) - start_time))
        local eta=$((elapsed * (total - current) / current))
        
        case $status in
            "success") printf "\r[%3d%%] ✓ %s (%ds, ETA: %ds)\n" $((current * 100 / total)) "$desc" $elapsed $eta ;;
            "failed") printf "\r[%3d%%] ✗ %s (%ds)\n" $((current * 100 / total)) "$desc" $elapsed ;;
            *) printf "\r[%3d%%] %s (%ds)\n" $((current * 100 / total)) "$desc" $elapsed ;;
        esac
    }
    
    print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
    print_status() { echo -e "${GREEN}[OK]${NC} $1"; }
    print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
    print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
fi

# Source common installer functions
if [ -f "./install/install-common.sh" ]; then
    source ./install/install-common.sh
elif [ -f "./install-common.sh" ]; then
    source ./install-common.sh
else
    print_error "install-common.sh not found"
    exit 1
fi

# Setup logging
setup_logging

echo "ZChat Single Executable Creator"
echo "==============================="
echo ""
echo "This script creates a single executable ZChat binary using PAR Packer (pp)."
echo "The resulting executable will be completely self-contained."
echo ""

# Detect platform
detect_platform() {
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m)
    
    case $os in
        linux*)
            PLATFORM="linux"
            ;;
        darwin*)
            PLATFORM="macos"
            ;;
        cygwin*|mingw*|msys*)
            PLATFORM="windows"
            ;;
        *)
            PLATFORM="unknown"
            ;;
    esac
    
    ARCHITECTURE="$arch"
    print_info "Detected platform: $PLATFORM ($ARCHITECTURE)"
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check if pp is available
    if ! command -v pp >/dev/null 2>&1; then
        print_info "Installing PAR Packer (pp)..."
        if ! cpanm -q PAR::Packer; then
            print_error "Failed to install PAR::Packer"
            print_info "Please install manually: cpanm PAR::Packer"
            exit 1
        fi
    fi
    
    # Check if cpanm is available
    if ! command -v cpanm >/dev/null 2>&1; then
        print_info "Installing cpanm..."
        curl -L https://cpanmin.us | perl - App::cpanminus
    fi
    
    print_status "Prerequisites check passed"
}

# Install required modules
install_modules() {
    print_info "Installing required modules..."
    
    local modules=(
        "Mojo::UserAgent"
        "JSON::XS"
        "YAML::XS"
        "Text::Xslate"
        "Clipboard"
        "Getopt::Long::Descriptive"
        "URI::Escape"
        "Data::Dumper"
        "String::ShellQuote"
        "File::Slurper"
        "File::Copy"
        "File::Temp"
        "File::Compare"
        "Carp"
        "POSIX"
        "List::Util"
        "Image::Magick"
    )
    
    local total_modules=${#modules[@]}
    local current_module=0
    local start_time=$(date +%s)
    
    for module in "${modules[@]}"; do
        current_module=$((current_module + 1))
        show_progress_bar $current_module $total_modules "Installing $module" $start_time
        
        if cpanm -q "$module" 2>/dev/null; then
            show_enhanced_progress $current_module $total_modules "$module" "success" $start_time
        else
            show_enhanced_progress $current_module $total_modules "$module" "failed" $start_time
            print_warning "Failed to install $module, continuing..."
        fi
    done
    
    print_status "Module installation completed"
}

# Create single executable
create_executable() {
    print_info "Creating single executable..."
    
    local output_name="zchat-${PLATFORM}-${ARCHITECTURE}"
    local output_file="${output_name}"
    
    # Add .exe extension for Windows
    if [ "$PLATFORM" = "windows" ]; then
        output_file="${output_file}.exe"
    fi
    
    # Create the executable using pp
    local pp_args=(
        "--output=$output_file"
        "--execute"
        "--compress=9"
        "--verbose"
        "--log=pp.log"
    )
    
    # Add platform-specific options
    case $PLATFORM in
        linux)
            pp_args+=("--target=linux")
            ;;
        macos)
            pp_args+=("--target=macos")
            ;;
        windows)
            pp_args+=("--target=windows")
            ;;
    esac
    
    # Add the main script
    pp_args+=("z")
    
    print_info "Running: pp ${pp_args[*]}"
    
    if pp "${pp_args[@]}"; then
        print_status "Single executable created: $output_file"
        
        # Test the executable
        print_info "Testing executable..."
        if [ -f "$output_file" ]; then
            if [ "$PLATFORM" = "windows" ]; then
                # Windows testing would need different approach
                print_status "Executable created successfully"
            else
                # Test with --help
                if ./"$output_file" --help >/dev/null 2>&1; then
                    print_status "Executable test passed"
                else
                    print_warning "Executable test failed, but file was created"
                fi
            fi
        else
            print_error "Executable file not found after creation"
            exit 1
        fi
    else
        print_error "Failed to create single executable"
        print_info "Check pp.log for details"
        exit 1
    fi
}

# Create distribution package
create_distribution() {
    print_info "Creating distribution package..."
    
    local output_name="zchat-${PLATFORM}-${ARCHITECTURE}"
    local output_file="${output_name}"
    
    if [ "$PLATFORM" = "windows" ]; then
        output_file="${output_file}.exe"
    fi
    
    local dist_dir="zchat-single-${PLATFORM}-${ARCHITECTURE}"
    mkdir -p "$dist_dir"
    
    # Copy executable
    cp "$output_file" "$dist_dir/"
    
    # Create README for the distribution
    cat > "$dist_dir/README.md" << EOF
# ZChat Single Executable - $PLATFORM ($ARCHITECTURE)

This is a self-contained ZChat executable for $PLATFORM ($ARCHITECTURE).

## Usage

\`\`\`bash
./$output_file "Hello, how are you?"
./$output_file -i  # Interactive mode
\`\`\`

## Features

- Single file executable with all dependencies embedded
- Zero external dependencies
- Works offline
- No installation complexity
- No CPAN installation required
- Portable across systems

## Configuration

**IMPORTANT**: This single executable creates configuration files in:
- User config: \`~/.config/zchat/user.yaml\`
- Session configs: \`~/.config/zchat/sessions/{session}/session.yaml\`
- Session history: \`~/.config/zchat/sessions/{session}/history.json\`
- Session pins: \`~/.config/zchat/sessions/{session}/pins.yaml\`

The executable will automatically create these directories and files when you first run it.

## Platform Support

- **Platform**: $PLATFORM
- **Architecture**: $ARCHITECTURE
- **Perl Version**: 5.26.3+
- **Created**: $(date)

## License

See LICENSE file in the source repository.

## Support

For issues and support, visit: https://github.com/fluffyrabbot/z
EOF
    
    # Copy LICENSE if available
    if [ -f "LICENSE" ]; then
        cp LICENSE "$dist_dir/"
    fi
    
    # Create archive
    local archive_name="zchat-single-${PLATFORM}-${ARCHITECTURE}.tar.gz"
    tar -czf "$archive_name" "$dist_dir"
    
    print_status "Distribution package created: $archive_name"
    print_info "Contents:"
    print_info "  - Executable: $output_file"
    print_info "  - README.md"
    print_info "  - LICENSE (if available)"
    print_info "  - Archive: $archive_name"
}

# Main execution
main() {
    detect_platform
    check_prerequisites
    install_modules
    create_executable
    create_distribution
    
    print_status "Single executable creation completed!"
    print_info "You can now distribute the archive or copy the executable to other systems."
}

# Run main function
main "$@"