# ZChat Dependencies

This document lists all the Perl modules required for ZChat to function properly.

## Core Dependencies (Required)

These modules are essential for ZChat to run:

- **Mojo::UserAgent** - HTTP client for LLM API communication
- **JSON::XS** - Fast JSON parsing and generation
- **YAML::XS** - YAML configuration file handling
- **Text::Xslate** - Template engine for system prompts
- **Clipboard** - Clipboard access for --clipboard functionality

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
- **Term::ReadLine::Gnu** - GNU ReadLine support
- **Term::Size** - Terminal size detection

## Utility Dependencies

Additional modules for enhanced functionality:

- **Capture::Tiny** - Capturing STDOUT/STDERR
- **LWP::UserAgent** - HTTP client (dependency of Mojo::UserAgent)

## Optional Dependencies

These modules enable additional features but are not required:

- **Image::Magick** - Image processing for --img functionality
  - Enables: `z --img photo.jpg "What's in this image?"`
  - Enables: `z --clipboard` with image content

## System Dependencies

Required system packages:

- **Build tools**: `build-essential`, `gcc`, `make`
- **SSL libraries**: `libssl-dev`
- **Network tools**: `curl`, `wget`
- **ImageMagick** (if using Image::Magick): `libmagickwand-dev`, `imagemagick`

## Installation Commands

### Complete Installation (Recommended)
```bash
# Install system dependencies
sudo apt-get install build-essential libssl-dev curl wget

# Install Perl modules
eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
cpanm Mojo::UserAgent JSON::XS YAML::XS Text::Xslate Clipboard Getopt::Long::Descriptive URI::Escape Data::Dumper String::ShellQuote File::Slurper File::Copy File::Temp File::Compare Carp Term::ReadLine Term::ReadLine::Gnu Capture::Tiny LWP::UserAgent Term::Size
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