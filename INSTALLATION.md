# ZChat Complete Installation Guide

## Quick Start

**Recommended for most users:**
```bash
git clone https://github.com/yourusername/z
cd z
./install.sh
```

## Installation Methods

### 1. Unified Installer (Recommended)
**File:** `install.sh`  
**Usage:** `./install.sh [OPTIONS]`  
**Best for:** All users - single installer with multiple modes

The unified installer handles all installation scenarios with a single script.

**Installation Features:**
- **Robust error handling** - Optional module failures don't break installation
- **Cross-platform clipboard support** - Works in WSL2, Linux, macOS, and Windows
- **Progress indicators** - Progress bars for all installation steps
- **Smart dependency management** - Distinguishes between required and optional modules
- **Platform-specific dependencies** - Automatically detects and installs clipboard tools and build dependencies

**Installation Modes:**
- `./install.sh` - Standard installation (default)
- `./install.sh --minimal` - Core dependencies only
- `./install.sh --repair` - Repair existing installation
- `./install.sh --onboarding` - Run interactive tutorial

**Options:**
- `--verbose, -v` - Verbose output
- `--force, -f` - Force installation (overwrite existing)
- `--offline, -o` - Offline installation mode
- `--help, -h` - Show help

**Examples:**
```bash
# Smart installation (default - recommended)
./install.sh

# Minimal installation (core dependencies only)
./install.sh --minimal

# Standard installation with interactive prompts
./install.sh --standard

# Create self-contained bundle (recommended for distribution)
./install.sh --bundle

# Create single executable file (requires compilation)
./install.sh --single

# Repair existing installation
./install.sh --repair
```

### 2. Single Executable Options

**Two approaches for creating self-contained ZChat distributions:**

#### Option A: Static Bundle (`--bundle`) [RECOMMENDED]
**File:** `install/create-bundle.sh`  
**Usage:** `./install.sh --bundle` or `./install/create-bundle.sh [--verbose]`  
**Best for:** Reliable, portable distributions

- Creates a directory with all dependencies bundled locally
- No external CPAN dependencies required
- Works offline after creation
- More reliable across different systems
- No compilation required
- Recommended for most users

#### Option B: Single Executable (`--single`)
**File:** `install/create-single-executable.sh`  
**Usage:** `./install.sh --single` or `./install/create-single-executable.sh`  
**Best for:** True single-file distribution (advanced users)

- Creates a single binary file using PAR Packer
- Requires PAR::Packer installation and compilation
- May need system build dependencies (gcc, perl-dev)
- Can fail in WSL, containers, or minimal environments
- Best for distribution as a single file
- **Tip:** Use `--bundle` instead for better reliability

**File:** `install/create-platform-bundles.sh`  
**Usage:** `./install/create-platform-bundles.sh [platform] [arch]`  
**Best for:** Creating platform-specific optimized bundles

**File:** `install/create-optimized-bundle.sh`  
**Usage:** `./install/create-optimized-bundle.sh`  
**Best for:** Creating size-optimized bundles with only used modules

**File:** `install/repair-installation.sh`  
**Usage:** `./install/repair-installation.sh [--verbose]`  
**Best for:** Advanced repair operations

**Repair Options:**
1. Repair Dependencies - Reinstall missing Perl modules
2. Update Installation - Reinstall with latest version
3. Force Reinstall - Complete reinstall with backup
4. Clean Uninstall - Remove ZChat completely
5. Diagnose Issues - Check installation health
6. Restore from Backup - Restore from previous backup

**File:** `install/offline-installer.sh`  
**Usage:** `./install/offline-installer.sh --download` (with internet)  
**Usage:** `./install/offline-installer.sh --create-installer` (offline)  
**Best for:** Offline installation preparation

## Enhanced Features

### Backup Management
ZChat automatically creates backups during updates and force reinstalls. Backups are stored in:
- `~/.zchat-backup-*` - Complete installation backups
- `~/.config/zchat.backup.*` - Configuration-only backups

**Backup Restoration:**
- Use `./install.sh --repair` and select option 6
- Automatic backup discovery and validation
- Interactive backup selection with timestamps
- Safe restoration with confirmation prompts

### Progress Indicators
All installers now feature:
- **Unicode Progress Bars**: Beautiful progress indicators with ETA
- **Status Indicators**: Success, failed, warning indicators
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

### Advanced Bundle Creation
The installer now supports multiple bundle creation methods:

#### Single Executable (`--single`)
- Creates a single file executable using PAR Packer (pp)
- Contains the entire ZChat application in one file
- Ultimate portability - just copy one file and run
- Platform-specific optimization
- Zero external dependencies

**About PAR Packer (pp):**
PAR Packer is a Perl utility that creates standalone executables from Perl applications. It bundles:
- The entire Perl interpreter
- All required Perl modules
- Your application code
- All dependencies

The result is a single executable file that runs on the target platform without requiring Perl or any modules to be installed. This is similar to how tools like PyInstaller work for Python applications.

**Configuration Files:**
The single executable will create configuration files in the standard locations:
- User config: `~/.config/zchat/user.yaml`
- Session configs: `~/.config/zchat/sessions/{session}/session.yaml`
- Session history: `~/.config/zchat/sessions/{session}/history.json`
- Session pins: `~/.config/zchat/sessions/{session}/pins.yaml`

These files are created automatically when you first run the executable.

#### Platform-Specific Bundles (`--platform`)
- Creates optimized bundles for specific platforms (Linux, macOS, Windows)
- Architecture-specific builds (x86_64, ARM64)
- Platform-optimized performance
- Reduced bundle size per platform

#### Size-Optimized Bundles (`--optimized`)
- Only includes modules actually used by ZChat
- Minimal bundle size for faster downloads
- Reduced storage requirements
- Faster transfers and deployment

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
- Capture::Tiny - Capturing STDOUT/STDERR
- LWP::UserAgent - HTTP client

### Optional Modules (Enhanced Features)
- Image::Magick - Image processing for --img functionality
  - Note: Requires ImageMagick system libraries, often fails to install
- Text::Xslate - Template engine for system prompts
  - Note: Requires C++ compiler, can fail on minimal systems
- Term::ReadLine::Gnu - Enhanced GNU ReadLine support
  - Note: Requires GNU ReadLine development libraries
- Term::Size - Terminal size detection
  - Note: May fail on some terminal environments

### System Dependencies
- Build tools: build-essential, gcc, make
- SSL libraries: libssl-dev
- Network tools: curl, wget
- Clipboard support: xclip (WSL2/Linux), automatically installed
- ImageMagick (if using Image::Magick): libmagickwand-dev, imagemagick

## Troubleshooting

### Common Issues

**Permission Denied**
```bash
chmod +x install.sh
chmod +x install/*.sh
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

**Optional Module Failures**
```bash
# These warnings are normal and non-fatal:
# [WARNING] Failed to install optional module: Image::Magick
# [INFO] This is non-fatal - image processing features will be disabled

# Optional modules that may fail:
# - Image::Magick (requires ImageMagick system libraries)
# - Text::Xslate (requires C++ compiler)
# - Term::ReadLine::Gnu (requires GNU ReadLine development libraries)
# - Term::Size (may fail on some terminal environments)
```

**Environment Setup**
```bash
# Add to ~/.bashrc
echo 'eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)' >> ~/.bashrc
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

**After Installation**
```bash
# Important: Start a new bash session to use the 'z' command
# Or run: source ~/.bashrc to reload your shell

# Test the installation
z --status
z --help
```

### Getting Help

1. **Check installation status:**
   ```bash
   z --status
   ```

2. **Run repair installer:**
   ```bash
   ./install.sh --repair
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