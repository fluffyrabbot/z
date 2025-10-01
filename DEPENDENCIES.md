# ZChat Dependencies

This document lists all the Perl modules required for ZChat to function properly.

## Core Dependencies (Required)

These modules are essential for ZChat to run:

- **Mojo::UserAgent** - HTTP client for LLM API communication
- **JSON::XS** - Fast JSON parsing and generation
- **YAML::XS** - YAML configuration file handling
- **xclip** - Clipboard access for --clipboard functionality (WSL2/Linux)
  - Note: `wl-copy`/`wl-paste` (Wayland) doesn't work in WSL2
  - WSL2 uses X11/WSLg, so `xclip` is the correct clipboard tool

## Standard Library Dependencies

These are typically included with Perl but may need explicit installation:

- **Getopt::Long::Descriptive** - Enhanced command-line option parsing
- **URI::Escape** - URL encoding/decoding
- **Data::Dumper** - Data structure debugging
- **String::ShellQuote** - Safe shell command construction
- **File::Slurper** - Simple file I/O operations
- **File::Copy** - File copying operations
- **File::Temp** - Temporary file creation
- **File::Compare** - File comparison utilities
- **Carp** - Error reporting utilities

## Terminal Dependencies

Required for interactive mode and terminal operations:

- **Term::ReadLine** - Command-line editing and history

## Utility Dependencies

Additional modules for enhanced functionality:

- **Capture::Tiny** - Capturing STDOUT/STDERR
- **LWP::UserAgent** - HTTP client (dependency of Mojo::UserAgent)

## Optional Dependencies

These modules enable additional features but are not required:

- **Image::Magick** - Image processing for --img functionality
  - Enables: `z --img photo.jpg "What's in this image?"`
  - Enables: `z --clipboard` with image content
  - Note: Requires ImageMagick system libraries, often fails to install

- **Text::Xslate** - Template engine for system prompts
  - Enables: Advanced prompt templating features
  - Note: Requires C++ compiler, can fail on minimal systems

- **Term::ReadLine::Gnu** - Enhanced GNU ReadLine support
  - Enables: Advanced command-line editing features
  - Note: Requires GNU ReadLine development libraries

- **Term::Size** - Terminal size detection
  - Enables: Dynamic terminal-aware formatting
  - Note: May fail on some terminal environments

## System Dependencies

Required system packages:

- **Build tools**: `build-essential`, `gcc`, `make`, `pkg-config`
- **SSL libraries**: `libssl-dev`, `libcrypto`
- **Network tools**: `curl`, `wget`
- **Terminal libraries**: `libreadline-dev`, `libncurses-dev`
- **Compression**: `zlib1g-dev`
- **ImageMagick** (if using Image::Magick): `libmagickwand-dev`, `imagemagick`

## Platform-Specific Dependencies

### Clipboard Support
- **WSL2/Linux X11**: `xclip` (automatically installed)
- **Linux Wayland**: `wl-clipboard` (wl-paste/wl-copy)
- **macOS**: `pbpaste` (built-in)
- **Windows**: `powershell` (built-in)

### Terminal Support
- **Enhanced ReadLine**: `libreadline-dev` (for Term::ReadLine::Gnu)
- **Terminal Size**: `libncurses-dev` (for Term::Size)
- **Color Support**: Detected automatically

### Build Environment
- **Compiler**: `gcc` 4.9+ or `clang` 3.5+
- **Make**: `make` 4.0+
- **pkg-config**: For library detection
- **Development Headers**: Automatically detected and installed

## Installation Commands

### Complete Installation (Recommended)
```bash
# Install system dependencies
sudo apt-get install build-essential libssl-dev curl wget

# Install Perl modules
eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
cpanm Mojo::UserAgent JSON::XS YAML::XS Text::Xslate Getopt::Long::Descriptive URI::Escape Data::Dumper String::ShellQuote File::Slurper File::Copy File::Temp File::Compare Carp Term::ReadLine Term::ReadLine::Gnu Capture::Tiny LWP::UserAgent Term::Size
```

### With Image Processing
```bash
# Add ImageMagick system library
sudo apt-get install libmagickwand-dev imagemagick

# Install Image::Magick (may require MAGICK_HOME for compatibility)
export MAGICK_HOME=/usr/include/ImageMagick-6  # Adjust path as needed
cpanm Image::Magick
```

## Troubleshooting

### Missing Modules
If you get "Can't locate X.pm" errors, install the missing module:
```bash
cpanm ModuleName
```

### Image::Magick Issues
If Image::Magick fails to install:
1. Install system ImageMagick: `sudo apt-get install libmagickwand-dev`
2. Set MAGICK_HOME: `export MAGICK_HOME=/usr/include/ImageMagick-6`
3. Install: `cpanm Image::Magick`

### Environment Setup
Always set up the Perl environment before using ZChat:
```bash
eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
```

Or add to your `~/.bashrc`:
```bash
echo 'eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)' >> ~/.bashrc
```