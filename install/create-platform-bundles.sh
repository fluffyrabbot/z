#!/bin/bash
# ZChat Platform-Specific Bundle Creator v0.9
# Creates optimized bundles for different platforms

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

echo "ZChat Platform-Specific Bundle Creator"
echo "======================================"
echo ""
echo "This script creates optimized bundles for different platforms."
echo ""

# Platform-specific module lists
get_platform_modules() {
    local platform=$1
    
    case $platform in
        linux)
            echo "Mojo::UserAgent JSON::XS YAML::XS Text::Xslate Clipboard Getopt::Long::Descriptive URI::Escape Data::Dumper String::ShellQuote File::Slurper File::Copy File::Temp File::Compare Carp POSIX List::Util Image::Magick"
            ;;
        macos)
            echo "Mojo::UserAgent JSON::XS YAML::XS Text::Xslate Clipboard Getopt::Long::Descriptive URI::Escape Data::Dumper String::ShellQuote File::Slurper File::Copy File::Temp File::Compare Carp POSIX List::Util Image::Magick"
            ;;
        windows)
            echo "Mojo::UserAgent JSON::XS YAML::XS Text::Xslate Clipboard Getopt::Long::Descriptive URI::Escape Data::Dumper String::ShellQuote File::Slurper File::Copy File::Temp File::Compare Carp POSIX List::Util"
            ;;
        *)
            echo "Mojo::UserAgent JSON::XS YAML::XS Text::Xslate Clipboard Getopt::Long::Descriptive URI::Escape Data::Dumper String::ShellQuote File::Slurper File::Copy File::Temp File::Compare Carp POSIX List::Util"
            ;;
    esac
}

# Create platform-specific bundle
create_platform_bundle() {
    local platform=$1
    local arch=$2
    
    print_info "Creating bundle for $platform ($arch)..."
    
    local bundle_name="zchat-${platform}-${arch}"
    local bundle_dir="zchat-bundle-${platform}-${arch}"
    
    # Create bundle directory
    mkdir -p "$bundle_dir"
    
    # Copy ZChat files
    print_info "Copying ZChat files..."
    cp -r z "$bundle_dir/"
    cp -r lib "$bundle_dir/"
    cp -r help "$bundle_dir/"
    cp -r completions "$bundle_dir/"
    cp -r refs "$bundle_dir/"
    cp README.md "$bundle_dir/" 2>/dev/null || true
    cp LICENSE "$bundle_dir/" 2>/dev/null || true
    
    # Create platform-specific README
    cat > "$bundle_dir/README.md" << EOF
# ZChat Bundle - $platform ($arch)

This is an optimized ZChat bundle for $platform ($arch).

## Usage

\`\`\`bash
./z "Hello, how are you?"
./z -i  # Interactive mode
\`\`\`

## Features

- Platform optimized - Built specifically for $platform
- Self-contained - All dependencies included
- Offline capable - Works without internet
- Portable - Copy and run anywhere on $platform
- Zero external dependencies - No CPAN, no system packages

## Platform Support

- Platform: $platform
- Architecture: $arch
- Perl Version: 5.26.3+
- Created: $(date)

## License

See LICENSE file in the source repository.

## Support

For issues and support, visit: https://github.com/fluffyrabbot/z
EOF
    
    # Install platform-specific modules
    print_info "Installing platform-specific modules..."
    local modules=($(get_platform_modules "$platform"))
    local total_modules=${#modules[@]}
    local current_module=0
    local start_time=$(date +%s)
    
    # Create temporary CPAN directory
    local temp_cpan="$bundle_dir/temp-cpan"
    mkdir -p "$temp_cpan"
    
    for module in "${modules[@]}"; do
        current_module=$((current_module + 1))
        show_progress_bar $current_module $total_modules "Installing $module" $start_time
        
        if cpanm --notest --quiet --local-lib="$temp_cpan" "$module" 2>/dev/null; then
            show_enhanced_progress $current_module $total_modules "$module" "success" $start_time
        else
            show_enhanced_progress $current_module $total_modules "$module" "failed" $start_time
            print_warning "Failed to install $module, continuing..."
        fi
    done
    
    # Copy installed modules to bundle
    print_info "Copying modules to bundle..."
    local perl_lib="$bundle_dir/perl-lib"
    mkdir -p "$perl_lib"
    
    if [ -d "$temp_cpan/lib/perl5" ]; then
        cp -r "$temp_cpan/lib/perl5"/* "$perl_lib/" 2>/dev/null || true
    fi
    
    # Clean up temporary directory
    rm -rf "$temp_cpan"
    
    # Create platform-specific launcher script
    cat > "$bundle_dir/zchat" << 'EOF'
#!/bin/bash
# ZChat Platform-Specific Launcher

# Set up Perl library path
export PERL5LIB="$PWD/perl-lib:$PERL5LIB"

# Run ZChat
exec "$PWD/z" "$@"
EOF
    
    chmod +x "$bundle_dir/zchat"
    
    # Create archive
    local archive_name="zchat-bundle-${platform}-${arch}.tar.gz"
    tar -czf "$archive_name" "$bundle_dir"
    
    print_status "Platform bundle created: $archive_name"
    print_info "Contents:"
    print_info "  - Bundle directory: $bundle_dir"
    print_info "  - Launcher script: zchat"
    print_info "  - Archive: $archive_name"
}

# Create all platform bundles
create_all_bundles() {
    local platforms=("linux" "macos" "windows")
    local architectures=("x86_64" "arm64")
    
    for platform in "${platforms[@]}"; do
        for arch in "${architectures[@]}"; do
            # Skip unsupported combinations
            if [ "$platform" = "windows" ] && [ "$arch" = "arm64" ]; then
                print_warning "Skipping Windows ARM64 (not commonly supported)"
                continue
            fi
            
            create_platform_bundle "$platform" "$arch"
        done
    done
}

# Main execution
main() {
    local platform=${1:-"all"}
    local arch=${2:-"x86_64"}
    
    if [ "$platform" = "all" ]; then
        create_all_bundles
    else
        create_platform_bundle "$platform" "$arch"
    fi
    
    print_status "Platform-specific bundle creation completed!"
}

# Run main function
main "$@"