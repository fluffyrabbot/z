# ZChat Complete Installation Guide

## Quick Start

**Recommended for most users:**
```bash
git clone https://github.com/yourusername/z
cd z
./install-master.sh
```

## Installation Methods

### 1. Master Installer (Recommended)
**File:** `install-master.sh`  
**Usage:** `./install-master.sh [--verbose] [--force]`  
**Best for:** New users who want guidance

Presents a menu of installation options with descriptions.

### 2. Static Bundle (Most Reliable)
**File:** `create-bundle.sh`  
**Usage:** `./create-bundle.sh [--verbose]`  
**Best for:** Portability without CPAN complexity

Creates a self-contained bundle with all dependencies downloaded locally.

### 3. Standard Installation (Full Features)
**File:** `install.sh`  
**Usage:** `./install.sh [--verbose] [--force] [--offline]`  
**Best for:** Complete functionality with all features

### 4. Minimal Installation (Quick Setup)
**File:** `install-deps-minimal.sh`  
**Usage:** `./install-deps-minimal.sh [--verbose] [--offline]`  
**Best for:** Fast setup, core functionality only

### 5. Adaptive Installation (Smart)
**File:** `install-adaptive.sh`  
**Usage:** `./install-adaptive.sh [--verbose] [--force]`  
**Best for:** Automatic environment detection and optimal method selection

### 6. Repair Installation (Maintenance)
**File:** `repair-installation.sh`  
**Usage:** `./repair-installation.sh [--verbose]`  
**Best for:** Fixing existing installations

### 7. Offline Installation
**File:** `offline-installer.sh`  
**Usage:** `./offline-installer.sh --download` (with internet)  
**Usage:** `./offline-installer.sh --create-installer` (offline)  
**Best for:** Installing without internet connection

## Enhanced Features

### Progress Indicators
All installers now feature:
- **Unicode Progress Bars**: Beautiful ██░░ progress indicators with ETA
- **Status Indicators**: ✓ (success), ✗ (failed), ⚠ (warning)
- **Retry Logic**: Automatic retry with exponential backoff (2s, 4s, 8s delays)

### Command Line Options
- **`--verbose` / `-v`**: Detailed output and logging
- **`--force` / `-f`**: Override existing installation protection
- **`--offline` / `-o`**: Offline installation mode

### Validation and Testing
- **Pre-flight Checks**: Validates Perl version, internet, disk space, permissions
- **Post-installation Testing**: Verifies `z` command and module loading
- **Comprehensive Logging**: Saves installation logs to `~/.zchat/install.log`

### Interactive Features
- **Dependency Selection**: Choose between core and optional modules
- **Installation Protection**: Detects existing installations and suggests repair
- **Configuration Backup**: Automatically backs up existing configs

## LLM Server Configuration

After installation, configure your LLM server:

### OpenAI
```bash
export OPENAI_BASE_URL=https://api.openai.com/v1
export OPENAI_API_KEY=your-api-key-here
```

### Local llama.cpp
```bash
export LLAMA_URL=http://localhost:8080
```

### Ollama
```bash
export OLLAMA_BASE_URL=http://localhost:11434
```

### Other OpenAI-Compatible APIs
```bash
export OPENAI_BASE_URL=http://your-api-endpoint/v1
export OPENAI_API_KEY=your-key-here
```

## Dependencies

### Core Perl Modules (Required)
- Mojo::UserAgent - HTTP client for LLM API communication
- JSON::XS - Fast JSON parsing and generation
- YAML::XS - YAML configuration file handling
- Text::Xslate - Template engine for system prompts
- Clipboard - Clipboard access for --clipboard functionality
- Getopt::Long::Descriptive - Enhanced command-line option parsing
- URI::Escape - URL encoding/decoding
- Data::Dumper - Data structure debugging
- String::ShellQuote - Safe shell command construction
- File::Slurper - Simple file I/O operations
- File::Copy - File copying operations
- File::Temp - Temporary file creation
- File::Compare - File comparison utilities
- Carp - Error reporting utilities
- Term::ReadLine - Command-line editing and history
- Term::ReadLine::Gnu - GNU ReadLine support
- Term::Size - Terminal size detection
- Capture::Tiny - Capturing STDOUT/STDERR
- LWP::UserAgent - HTTP client

### Optional Modules
- Image::Magick - Image processing for --img functionality

### System Dependencies
- Build tools: build-essential, gcc, make
- SSL libraries: libssl-dev
- Network tools: curl, wget
- ImageMagick (if using Image::Magick): libmagickwand-dev, imagemagick

## Troubleshooting

### Common Issues

**Permission Denied**
```bash
chmod +x install-*.sh
```

**Perl Version Too Old**
```bash
perl --version  # Check version
# ZChat requires Perl 5.26.3+
```

**Missing Dependencies**
```bash
# For standard installation
sudo apt-get install build-essential libssl-dev curl wget
```

**CPAN Issues**
```bash
# Install cpanm
curl -L https://cpanmin.us | perl - App::cpanminus
```

**Environment Setup**
```bash
# Add to ~/.bashrc
echo 'eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)' >> ~/.bashrc
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Getting Help

1. **Check installation status:**
   ```bash
   z --status
   ```

2. **Run repair installer:**
   ```bash
   ./repair-installation.sh
   ```

3. **View help:**
   ```bash
   z --help
   ```

## Basic Usage

### Simple Queries
```bash
# Simple query
z "Hello, how are you?"

# Interactive mode
z -i

# With a specific session
z -n myproject "What should I focus on?"
```

### Session Management
```bash
# Create a project session
z -n work/project1 "Design the API"

# Hierarchical sessions
z -n work/project1/api "Design REST endpoints"
z -n work/project1/frontend "Build React components"

# Set session as default for this shell
z -n work/urgent --sp
z "What should I prioritize?"  # Uses work/urgent automatically
```

### Pin System
```bash
# Add persistent context
z --pin "You are terse and precise"
z --pin-user "This is a Perl project"
z --pin-ua-pipe 'How to regex?|||Use \d+ with anchors'

# List and manage pins
z --pins-list
z --pins-sum
z --pin-rm 0
z --pins-clear
```

### System Prompts
```bash
# From file
z --system-file prompts/coding.md "Write a function"

# From string
z --system-str "You are a helpful assistant" "Explain this"

# Store as default
z --system-file prompts/api.md --su  # User global
z --system-str "Focus on critical issues" --sp  # Shell session
z --system-file prompts/project.md --ss  # Session specific
```

### Advanced Features
```bash
# Token counting
z -T "Count tokens in this text"
z --tokens-full "Detailed breakdown"

# History management
z --wipe  # Clear conversation
z --wipeold 1.5h  # Remove old messages
z -E  # Edit history in editor

# Multi-modal
z --clipboard "What's in this image?"
z --img photo.jpg "Analyze this image"

# Model information
z --metadata  # Show model details
z --ctx  # Show context window size
```

## Common Workflows

### Project Setup
```bash
# Set up a new project session
z -n project/api --system-file prompts/api.md --ss
z --pin-sys "Focus on REST API design"
z --pin-user "Use modern Perl practices"
z "How should I structure the authentication?"
```

### Shell Session
```bash
# Set up shell-specific context
z -n work/urgent --system-str "Focus on critical issues" --sp
z "What should I prioritize?"
z "Review the latest changes"
# All commands in this shell use work/urgent with urgent prompt
```

### Interactive Exploration
```bash
z -i
>> Tell me about Perl's postderef feature
>> Can you show an example?
>> How does it compare to other deref syntax?
```

## Configuration Precedence

ZChat uses a sophisticated precedence system:

```
System Defaults → User Global → Environment → Shell Session → Session Specific → CLI
```

- **CLI flags**: Override everything (temporary)
- **Session settings**: Override user defaults for specific sessions
- **Shell settings**: Override user defaults for this terminal
- **User settings**: Override system defaults globally
- **System defaults**: Provide sensible fallbacks

## Storage Scopes

- `--store-user (-S)`: Global user preferences
- `--store-pproc (--sp)`: Shell session settings (terminal-scoped)
- `--store-session (--ss)`: Session-specific settings

## Getting Help

```bash
z --help              # Full CLI reference
z --help-cli          # Basic CLI usage
z --help-pins         # Pin system documentation
z --status            # Current configuration
```

## Next Steps

1. Configure your LLM server (see LLM Server Configuration above)
2. Run `./onboarding.pl` for a comprehensive tour of features
3. Try the interactive mode: `z -i`
4. Set up your first project session
5. Explore the pin system for consistent behavior
6. Read the full documentation for advanced usage