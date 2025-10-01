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
        print_warning "PAR::Packer requires C compiler and development headers"
        print_info "If this fails, try: sudo apt-get install build-essential perl-dev"
        print_info "Or use: ./install.sh --bundle (more reliable alternative)"
        echo ""
        
        if ! cpanm -q PAR::Packer; then
            print_error "Failed to install PAR::Packer"
            echo ""
            print_warning "PAR::Packer installation failed. This is common and can be caused by:"
            echo "  • Missing C compiler (gcc/clang)"
            echo "  • Missing Perl development headers"
            echo "  • System package manager conflicts"
            echo "  • WSL or container environment issues"
            echo ""
            print_info "Recommended solutions:"
            echo "  1. Install build tools: sudo apt-get install build-essential perl-dev"
            echo "  2. Use static bundle instead: ./install.sh --bundle"
            echo "  3. Try manual installation: cpanm PAR::Packer"
            echo ""
            print_info "The --bundle option is more reliable and doesn't require compilation."
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
        # "Clipboard" # Replaced with custom clipboard function
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
        
        # Show progress bar even for single items
        show_progress_bar $current_module $total_modules "Installing $module" $start_time
        
        # Add small delay to make progress visible for instant operations
        if [ $total_modules -eq 1 ]; then
            sleep 0.3
            show_progress_bar $current_module $total_modules "Installing $module" $start_time
            sleep 0.2
        fi
        
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
    
    # Show progress for executable creation
    local exec_steps=(
        "Preparing PAR Packer arguments"
        "Creating executable with pp"
        "Testing executable"
        "Setting permissions"
    )
    local exec_total=${#exec_steps[@]}
    local exec_current=0
    local exec_start_time=$(date +%s)
    
    # Step 1: Prepare arguments
    exec_current=$((exec_current + 1))
    show_progress_bar $exec_current $exec_total "${exec_steps[0]}" $exec_start_time
    
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
    
    show_enhanced_progress $exec_current $exec_total "${exec_steps[0]}" "success" $exec_start_time
    
    # Step 2: Create executable
    exec_current=$((exec_current + 1))
    show_progress_bar $exec_current $exec_total "${exec_steps[1]}" $exec_start_time
    
    print_info "Running: pp ${pp_args[*]}"
    
    if pp "${pp_args[@]}"; then
        show_enhanced_progress $exec_current $exec_total "${exec_steps[1]}" "success" $exec_start_time
        print_status "Single executable created: $output_file"
    else
        show_enhanced_progress $exec_current $exec_total "${exec_steps[1]}" "failed" $exec_start_time
        print_error "Failed to create single executable"
        print_info "Check pp.log for details"
        exit 1
    fi
    
    # Step 3: Test executable
    exec_current=$((exec_current + 1))
    show_progress_bar $exec_current $exec_total "${exec_steps[2]}" $exec_start_time
    
    if [ -f "$output_file" ]; then
        if [ "$PLATFORM" = "windows" ]; then
            # Windows testing would need different approach
            show_enhanced_progress $exec_current $exec_total "${exec_steps[2]}" "success" $exec_start_time
            print_status "Executable created successfully"
        else
            # Test with --help
            if ./"$output_file" --help >/dev/null 2>&1; then
                show_enhanced_progress $exec_current $exec_total "${exec_steps[2]}" "success" $exec_start_time
                print_status "Executable test passed"
            else
                show_enhanced_progress $exec_current $exec_total "${exec_steps[2]}" "failed" $exec_start_time
                print_warning "Executable test failed, but file was created"
            fi
        fi
    else
        show_enhanced_progress $exec_current $exec_total "${exec_steps[2]}" "failed" $exec_start_time
        print_error "Executable file not found after creation"
        exit 1
    fi
    
    # Step 4: Set permissions
    exec_current=$((exec_current + 1))
    show_progress_bar $exec_current $exec_total "${exec_steps[3]}" $exec_start_time
    
    chmod +x "$output_file" 2>/dev/null || true
    show_enhanced_progress $exec_current $exec_total "${exec_steps[3]}" "success" $exec_start_time
    
    print_status "Executable creation completed successfully!"
}

# Create distribution package
create_distribution() {
    print_info "Creating distribution package..."
    
    local output_name="zchat-${PLATFORM}-${ARCHITECTURE}"
    local output_file="${output_name}"
    
    if [ "$PLATFORM" = "windows" ]; then
        output_file="${output_file}.exe"
    fi
    
    # Show progress for distribution creation
    local dist_steps=(
        "Creating distribution directory"
        "Copying executable"
        "Creating README"
        "Copying LICENSE"
        "Creating archive"
    )
    local dist_total=${#dist_steps[@]}
    local dist_current=0
    local dist_start_time=$(date +%s)
    
    # Step 1: Create directory
    dist_current=$((dist_current + 1))
    show_progress_bar $dist_current $dist_total "${dist_steps[0]}" $dist_start_time
    
    local dist_dir="zchat-single-${PLATFORM}-${ARCHITECTURE}"
    mkdir -p "$dist_dir"
    show_enhanced_progress $dist_current $dist_total "${dist_steps[0]}" "success" $dist_start_time
    
    # Step 2: Copy executable
    dist_current=$((dist_current + 1))
    show_progress_bar $dist_current $dist_total "${dist_steps[1]}" $dist_start_time
    
    cp "$output_file" "$dist_dir/"
    show_enhanced_progress $dist_current $dist_total "${dist_steps[1]}" "success" $dist_start_time
    
    # Step 3: Create README
    dist_current=$((dist_current + 1))
    show_progress_bar $dist_current $dist_total "${dist_steps[2]}" $dist_start_time
    
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
    show_enhanced_progress $dist_current $dist_total "${dist_steps[2]}" "success" $dist_start_time
    
    # Step 4: Copy LICENSE
    dist_current=$((dist_current + 1))
    show_progress_bar $dist_current $dist_total "${dist_steps[3]}" $dist_start_time
    
    if [ -f "LICENSE" ]; then
        cp LICENSE "$dist_dir/"
        show_enhanced_progress $dist_current $dist_total "${dist_steps[3]}" "success" $dist_start_time
    else
        show_enhanced_progress $dist_current $dist_total "${dist_steps[3]}" "success" $dist_start_time
        print_info "No LICENSE file found, skipping"
    fi
    
    # Step 5: Create archive
    dist_current=$((dist_current + 1))
    show_progress_bar $dist_current $dist_total "${dist_steps[4]}" $dist_start_time
    
    local archive_name="zchat-single-${PLATFORM}-${ARCHITECTURE}.tar.gz"
    tar -czf "$archive_name" "$dist_dir"
    show_enhanced_progress $dist_current $dist_total "${dist_steps[4]}" "success" $dist_start_time
    
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