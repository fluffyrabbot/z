#!/bin/bash
# ZChat Size-Optimized Bundle Creator v0.9
# Creates bundles with only actually used modules

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

echo "ZChat Size-Optimized Bundle Creator"
echo "=================================="
echo ""
echo "This script creates bundles with only actually used modules."
echo ""

# Analyze module usage
analyze_module_usage() {
    print_info "Analyzing module usage..."
    
    local used_modules=()
    
    # Core modules (always used)
    local core_modules=(
        "Mojo::UserAgent"
        "JSON::XS"
        "YAML::XS"
        "Text::Xslate"
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
    )
    
    # Optional modules (conditionally used)
    local optional_modules=(
        "Clipboard"
        "Image::Magick"
    )
    
    # Check which optional modules are actually used
    for module in "${optional_modules[@]}"; do
        if grep -r "use $module" lib/ z 2>/dev/null | grep -v "use $module::" >/dev/null; then
            used_modules+=("$module")
            print_info "Found usage of $module"
        else
            print_info "Skipping unused module: $module"
        fi
    done
    
    # Add core modules
    used_modules+=("${core_modules[@]}")
    
    # Remove duplicates
    local unique_modules=()
    for module in "${used_modules[@]}"; do
        if [[ ! " ${unique_modules[@]} " =~ " ${module} " ]]; then
            unique_modules+=("$module")
        fi
    done
    
    printf '%s\n' "${unique_modules[@]}"
}

# Create optimized bundle
create_optimized_bundle() {
    print_info "Creating size-optimized bundle..."
    
    local bundle_name="zchat-optimized"
    local bundle_dir="zchat-bundle-optimized"
    
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
    
    # Create optimized README
    cat > "$bundle_dir/README.md" << EOF
# ZChat Size-Optimized Bundle

This is a size-optimized ZChat bundle containing only actually used modules.

## Usage

\`\`\`bash
./z "Hello, how are you?"
./z -i  # Interactive mode
\`\`\`

## Features

- ✅ **Size optimized** - Only includes actually used modules
- ✅ **Self-contained** - All dependencies included
- ✅ **Offline capable** - Works without internet
- ✅ **Portable** - Copy and run anywhere
- ✅ **Zero external dependencies** - No CPAN, no system packages
- ✅ **Minimal footprint** - Reduced bundle size

## Module Analysis

This bundle includes only modules that are actually used by ZChat:
EOF
    
    # Get used modules
    local used_modules=($(analyze_module_usage))
    
    # Add module list to README
    for module in "${used_modules[@]}"; do
        echo "- $module" >> "$bundle_dir/README.md"
    done
    
    cat >> "$bundle_dir/README.md" << EOF

## Platform Support

- **Perl Version**: 5.26.3+
- **Created**: $(date)
- **Total Modules**: ${#used_modules[@]}

## License

See LICENSE file in the source repository.

## Support

For issues and support, visit: https://github.com/fluffyrabbot/z
EOF
    
    # Install only used modules
    print_info "Installing used modules..."
    local total_modules=${#used_modules[@]}
    local current_module=0
    local start_time=$(date +%s)
    
    # Create temporary CPAN directory
    local temp_cpan="$bundle_dir/temp-cpan"
    mkdir -p "$temp_cpan"
    
    for module in "${used_modules[@]}"; do
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
    
    # Create optimized launcher script
    cat > "$bundle_dir/zchat" << 'EOF'
#!/bin/bash
# ZChat Size-Optimized Launcher

# Set up Perl library path
export PERL5LIB="$PWD/perl-lib:$PERL5LIB"

# Run ZChat
exec "$PWD/z" "$@"
EOF
    
    chmod +x "$bundle_dir/zchat"
    
    # Calculate bundle size
    local bundle_size=$(du -sh "$bundle_dir" | cut -f1)
    print_info "Bundle size: $bundle_size"
    
    # Create archive
    local archive_name="zchat-bundle-optimized.tar.gz"
    tar -czf "$archive_name" "$bundle_dir"
    
    local archive_size=$(du -sh "$archive_name" | cut -f1)
    print_info "Archive size: $archive_size"
    
    print_status "Size-optimized bundle created: $archive_name"
    print_info "Contents:"
    print_info "  - Bundle directory: $bundle_dir"
    print_info "  - Launcher script: zchat"
    print_info "  - Archive: $archive_name"
    print_info "  - Bundle size: $bundle_size"
    print_info "  - Archive size: $archive_size"
}

# Main execution
main() {
    create_optimized_bundle
    
    print_status "Size-optimized bundle creation completed!"
    print_info "This bundle contains only the modules actually used by ZChat."
}

# Run main function
main "$@"