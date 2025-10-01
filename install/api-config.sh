#!/bin/bash
# ZChat API Configuration Helper v0.8b

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
LIGHT_BLUE='\033[0;36m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[OK]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# API configuration function
configure_api() {
    echo ""
    echo "LLM Server Configuration"
    echo "========================"
    echo ""
    echo "ZChat needs to connect to an LLM server to work. You can configure this now"
    echo "or skip and set it up later manually."
    echo ""
    echo "Supported LLM servers:"
    echo "  - OpenAI API (GPT models)"
    echo "  - Local llama.cpp server"
    echo "  - Ollama (local models)"
    echo "  - Other OpenAI-compatible APIs"
    echo ""
    
    read -p "Configure LLM server now? (y/N): " -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Skipping API configuration"
        show_manual_setup_instructions
        return 0
    fi
    
    echo ""
    echo "Choose your LLM server:"
    echo "(Press Enter without selecting to see this menu again, or Ctrl+C to skip)"
    echo ""
    echo -e "${LIGHT_BLUE}1. OpenAI API${NC}"
    echo "   - GPT-3.5, GPT-4, and other OpenAI models"
    echo "   - Requires API key from https://platform.openai.com"
    echo ""
    echo -e "${LIGHT_BLUE}2. Local llama.cpp${NC}"
    echo "   - Run models locally on your machine"
    echo "   - No API key required, but need to run llama.cpp server"
    echo ""
    echo -e "${LIGHT_BLUE}3. Ollama${NC}"
    echo "   - Easy local model management"
    echo "   - No API key required, but need Ollama installed"
    echo ""
    echo -e "${LIGHT_BLUE}4. Custom OpenAI-compatible API${NC}"
    echo "   - Other services like Together AI, Anthropic, etc."
    echo "   - Requires API key and custom endpoint"
    echo ""
    echo -e "${LIGHT_BLUE}5. Skip configuration${NC}"
    echo "   - Set up manually later"
    echo ""
    
    while true; do
        read -p "Choose option (1-5): " -r
        echo ""
        
        case $REPLY in
            1)
                configure_openai
                break
                ;;
            2)
                configure_llamacpp
                break
                ;;
            3)
                configure_ollama
                break
                ;;
            4)
                configure_custom
                break
                ;;
            5)
                print_info "Skipping API configuration"
                show_manual_setup_instructions
                break
                ;;
            "")
                print_warning "No option selected. Please choose 1-5 or press Ctrl+C to skip."
                continue
                ;;
            *)
                print_warning "Invalid choice '$REPLY'. Please choose 1-5 or press Ctrl+C to skip."
                continue
                ;;
        esac
    done
}

# Configure OpenAI API
configure_openai() {
    echo ""
    print_info "Configuring OpenAI API..."
    echo ""
    echo "You'll need an API key from https://platform.openai.com"
    echo "The key should start with 'sk-' and look like: sk-1234567890abcdef..."
    echo ""
    
    read -p "Enter your OpenAI API key: " -s OPENAI_API_KEY
    echo ""
    
    if [ -z "$OPENAI_API_KEY" ]; then
        print_warning "No API key provided, skipping OpenAI configuration"
        return 0
    fi
    
    # Validate API key format
    if [[ ! "$OPENAI_API_KEY" =~ ^sk- ]]; then
        print_warning "API key doesn't look like a valid OpenAI key (should start with 'sk-')"
        read -p "Continue anyway? (y/N): " -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping OpenAI configuration"
            return 0
        fi
    fi
    
    # Set environment variables
    export OPENAI_BASE_URL="https://api.openai.com/v1"
    export OPENAI_API_KEY="$OPENAI_API_KEY"
    
    # Add to shell configuration
    add_to_shell_config "OPENAI_BASE_URL" "https://api.openai.com/v1"
    add_to_shell_config "OPENAI_API_KEY" "$OPENAI_API_KEY"
    
    print_status "OpenAI API configured successfully!"
    echo ""
    echo "Environment variables set:"
    echo "  OPENAI_BASE_URL=https://api.openai.com/v1"
    echo "  OPENAI_API_KEY=***${OPENAI_API_KEY: -4}"
    echo ""
    echo "You can now use ZChat with OpenAI models!"
}

# Configure llama.cpp
configure_llamacpp() {
    echo ""
    print_info "Configuring llama.cpp..."
    echo ""
    echo "llama.cpp runs models locally on your machine."
    echo "You need to download and run a llama.cpp server first."
    echo ""
    echo "Default llama.cpp server URL: http://localhost:8080"
    echo ""
    
    read -p "Enter llama.cpp server URL (default: http://localhost:8080): " LLAMA_URL
    LLAMA_URL=${LLAMA_URL:-http://localhost:8080}
    
    if [ -z "$LLAMA_URL" ]; then
        LLAMA_URL="http://localhost:8080"
    fi
    
    # Validate URL format
    if [[ ! "$LLAMA_URL" =~ ^https?:// ]]; then
        print_warning "URL doesn't look valid (should start with http:// or https://)"
        read -p "Continue anyway? (y/N): " -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping llama.cpp configuration"
            return 0
        fi
    fi
    
    # Set environment variables
    export LLAMA_URL="$LLAMA_URL"
    
    # Add to shell configuration
    add_to_shell_config "LLAMA_URL" "$LLAMA_URL"
    
    print_status "llama.cpp configured successfully!"
    echo ""
    echo "Environment variables set:"
    echo "  LLAMA_URL=$LLAMA_URL"
    echo ""
    echo "Make sure your llama.cpp server is running at $LLAMA_URL"
    echo "You can test with: curl $LLAMA_URL/health"
}

# Configure Ollama
configure_ollama() {
    echo ""
    print_info "Configuring Ollama..."
    echo ""
    echo "Ollama makes it easy to run models locally."
    echo "Install Ollama from https://ollama.ai if you haven't already."
    echo ""
    echo "Default Ollama URL: http://localhost:11434"
    echo ""
    
    read -p "Enter Ollama server URL (default: http://localhost:11434): " OLLAMA_BASE_URL
    OLLAMA_BASE_URL=${OLLAMA_BASE_URL:-http://localhost:11434}
    
    if [ -z "$OLLAMA_BASE_URL" ]; then
        OLLAMA_BASE_URL="http://localhost:11434"
    fi
    
    # Validate URL format
    if [[ ! "$OLLAMA_BASE_URL" =~ ^https?:// ]]; then
        print_warning "URL doesn't look valid (should start with http:// or https://)"
        read -p "Continue anyway? (y/N): " -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping Ollama configuration"
            return 0
        fi
    fi
    
    # Set environment variables
    export OLLAMA_BASE_URL="$OLLAMA_BASE_URL"
    
    # Add to shell configuration
    add_to_shell_config "OLLAMA_BASE_URL" "$OLLAMA_BASE_URL"
    
    print_status "Ollama configured successfully!"
    echo ""
    echo "Environment variables set:"
    echo "  OLLAMA_BASE_URL=$OLLAMA_BASE_URL"
    echo ""
    echo "Make sure Ollama is running at $OLLAMA_BASE_URL"
    echo "You can test with: curl $OLLAMA_BASE_URL/api/tags"
}

# Configure custom API
configure_custom() {
    echo ""
    print_info "Configuring custom OpenAI-compatible API..."
    echo ""
    echo "This is for services like Together AI, Anthropic, or other"
    echo "OpenAI-compatible APIs."
    echo ""
    
    read -p "Enter API base URL (e.g., https://api.together.xyz/v1): " CUSTOM_BASE_URL
    
    if [ -z "$CUSTOM_BASE_URL" ]; then
        print_warning "No URL provided, skipping custom API configuration"
        return 0
    fi
    
    # Validate URL format
    if [[ ! "$CUSTOM_BASE_URL" =~ ^https?:// ]]; then
        print_warning "URL doesn't look valid (should start with http:// or https://)"
        read -p "Continue anyway? (y/N): " -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping custom API configuration"
            return 0
        fi
    fi
    
    echo ""
    read -p "Enter API key: " -s CUSTOM_API_KEY
    echo ""
    
    if [ -z "$CUSTOM_API_KEY" ]; then
        print_warning "No API key provided, skipping custom API configuration"
        return 0
    fi
    
    # Set environment variables
    export OPENAI_BASE_URL="$CUSTOM_BASE_URL"
    export OPENAI_API_KEY="$CUSTOM_API_KEY"
    
    # Add to shell configuration
    add_to_shell_config "OPENAI_BASE_URL" "$CUSTOM_BASE_URL"
    add_to_shell_config "OPENAI_API_KEY" "$CUSTOM_API_KEY"
    
    print_status "Custom API configured successfully!"
    echo ""
    echo "Environment variables set:"
    echo "  OPENAI_BASE_URL=$CUSTOM_BASE_URL"
    echo "  OPENAI_API_KEY=***${CUSTOM_API_KEY: -4}"
    echo ""
    echo "You can now use ZChat with your custom API!"
}

# Add environment variable to shell configuration
add_to_shell_config() {
    local var_name="$1"
    local var_value="$2"
    
    # Add to .bashrc
    if [ -f ~/.bashrc ]; then
        if ! grep -q "ZChat.*$var_name" ~/.bashrc; then
            echo "" >> ~/.bashrc
            echo "# ZChat $var_name configuration" >> ~/.bashrc
            echo "export $var_name=\"$var_value\"" >> ~/.bashrc
        fi
    fi
    
    # Add to .zshrc
    if [ -f ~/.zshrc ]; then
        if ! grep -q "ZChat.*$var_name" ~/.zshrc; then
            echo "" >> ~/.zshrc
            echo "# ZChat $var_name configuration" >> ~/.zshrc
            echo "export $var_name=\"$var_value\"" >> ~/.zshrc
        fi
    fi
}

# Show manual setup instructions
show_manual_setup_instructions() {
    echo ""
    print_info "Manual LLM Server Setup"
    echo ""
    echo "To configure ZChat later, set these environment variables:"
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
    echo "For custom APIs:"
    echo "  export OPENAI_BASE_URL=https://your-api-endpoint.com/v1"
    echo "  export OPENAI_API_KEY=your-key-here"
    echo ""
    echo "Add these to your ~/.bashrc or ~/.zshrc for permanent setup."
    echo ""
    echo "Test your configuration with:"
    echo "  z --status"
    echo ""
}

# Test API configuration
test_api_config() {
    echo ""
    print_info "Testing API configuration..."
    
    if [ -n "$OPENAI_API_KEY" ] && [ -n "$OPENAI_BASE_URL" ]; then
        print_status "OpenAI API configured"
        echo "  Base URL: $OPENAI_BASE_URL"
        echo "  API Key: ***${OPENAI_API_KEY: -4}"
    fi
    
    if [ -n "$LLAMA_URL" ]; then
        print_status "llama.cpp configured"
        echo "  URL: $LLAMA_URL"
    fi
    
    if [ -n "$OLLAMA_BASE_URL" ]; then
        print_status "Ollama configured"
        echo "  URL: $OLLAMA_BASE_URL"
    fi
    
    if [ -z "$OPENAI_API_KEY" ] && [ -z "$LLAMA_URL" ] && [ -z "$OLLAMA_BASE_URL" ]; then
        print_warning "No LLM server configured"
        echo "ZChat will not work until you configure an LLM server."
    fi
}

# If script is run directly, show help
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    echo "ZChat API Configuration Helper v0.8b"
    echo "====================================="
    echo ""
    echo "This script helps configure LLM server connections for ZChat."
    echo ""
    echo "Usage:"
    echo "  source ./api-config.sh  # Load functions"
    echo "  configure_api           # Run configuration"
    echo ""
    echo "Or run directly:"
    echo "  ./api-config.sh"
    echo ""
    configure_api
fi