#!/bin/bash
# ZChat Master Installer v0.8b
# Enhanced installer with progress bars and validation

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
fi

echo "ZChat Master Installer"
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
        echo -e "  ${LIGHT_BLUE}./install-master.sh --force${NC}"
        echo ""
        echo -e "${RED}Exiting to protect existing installation.${NC}"
        echo "Use --force flag to override this protection."
        exit 0
    fi
fi

echo "Choose your installation method based on your needs:"
echo ""

echo -e "${LIGHT_BLUE}1. Static Bundle (Recommended for portability)${NC}"
echo "   - Self-contained bundle with downloaded dependencies"
echo "   - No CPAN installation required"
echo "   - Portable across systems"
echo "   - Good balance of features and reliability"
echo ""

echo -e "${LIGHT_BLUE}2. Standard Installation (Full features)${NC}"
echo "   - Complete ZChat with all features"
echo "   - Requires CPAN and system packages"
echo "   - Most feature-complete"
echo "   - May require troubleshooting"
echo ""

echo -e "${LIGHT_BLUE}3. Minimal Installation (Quick setup)${NC}"
echo "   - Core dependencies only"
echo "   - Fast installation"
echo "   - Image processing disabled"
echo "   - Good for basic usage"
echo ""

echo -e "${LIGHT_BLUE}4. Adaptive Installation (Recommended)${NC}"
echo "   - Automatically detects your environment"
echo "   - Chooses best installation method"
echo "   - Handles WSL, containers, and special cases"
echo "   - Most intelligent option"
echo ""

echo -e "${LIGHT_BLUE}5. Repair Existing Installation${NC}"
echo "   - Fix corrupted or incomplete installations"
echo "   - Update dependencies and modules"
echo "   - Diagnose and resolve issues"
echo "   - For existing ZChat users"
echo ""

read -p "Choose installation method (1-5): " -r
echo ""

case $REPLY in
    1)
        print_info "Selected: Static Bundle Installation"
        echo ""
        if [ -f "./create-bundle.sh" ]; then
            ./create-bundle.sh
        else
            print_error "create-bundle.sh not found"
            exit 1
        fi
        ;;
    2)
        print_info "Selected: Standard Installation"
        echo ""
        if [ -f "./install.sh" ]; then
            ./install.sh
        else
            print_error "install.sh not found"
            exit 1
        fi
        ;;
    3)
        print_info "Selected: Minimal Installation"
        echo ""
        if [ -f "./install-deps-minimal.sh" ]; then
            ./install-deps-minimal.sh
        else
            print_error "install-deps-minimal.sh not found"
            exit 1
        fi
        ;;
    4)
        print_info "Selected: Adaptive Installation"
        echo ""
        if [ -f "./install-adaptive.sh" ]; then
            ./install-adaptive.sh
        else
            print_error "install-adaptive.sh not found"
            exit 1
        fi
        ;;
    5)
        print_info "Selected: Repair Existing Installation"
        echo ""
        if [ -f "./repair-installation.sh" ]; then
            ./repair-installation.sh
        else
            print_error "repair-installation.sh not found"
            exit 1
        fi
        ;;
    *)
        print_error "Invalid choice. Please select 1-5."
        exit 1
        ;;
esac

echo ""
print_status "Installation completed!"
echo ""
echo "Next steps:"
echo "1. Set up your LLM server (OpenAI, llama.cpp, Ollama, etc.)"
echo "2. Configure environment variables"
echo "3. Start using ZChat!"
echo ""
echo "For help:"
echo "  - Read the README.md file"
echo "  - Check the help/ directory"
echo "  - Run: z --help (after installation)"