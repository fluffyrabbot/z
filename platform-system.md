# ZChat Platform System

The ZChat installer automatically detects your platform and environment, then installs dependencies and configures paths accordingly to provide the best possible experience. This document explains how the platform system works and what it means for you.

## Supported Platforms

ZChat works seamlessly across:

- **Windows** (via WSL2, PowerShell, or native Windows)
- **macOS** (Intel and Apple Silicon)
- **Linux** (Ubuntu, Debian, CentOS, Fedora, Arch, Alpine, etc.)
- **FreeBSD**
- **Docker containers** and cloud environments

## Automatic Detection

When you install ZChat, it automatically detects:

### **Operating System**
- Windows, macOS, Linux, FreeBSD
- Specific distributions (Ubuntu, CentOS, Arch, etc.)
- Version information

### **Environment Type**
- **WSL2**: Windows Subsystem for Linux
- **Native**: Direct installation on the OS
- **Container**: Docker, Kubernetes, or similar
- **Headless**: Server environments without display

### **Display System**
- **X11**: Traditional Linux display server
- **Wayland**: Modern Linux display server
- **WSLg**: Windows 11's GUI subsystem for WSL
- **macOS**: Native display system
- **Headless**: No display server

### **Terminal Capabilities**
- Color support
- Terminal size detection
- Terminal emulator type
- Remote terminal detection (SSH, etc.)

## Automatic Installation

Based on what ZChat detects, it automatically installs:

### **Clipboard Tools**
- **WSL2/Linux X11**: `xclip` for clipboard access
- **Linux Wayland**: `wl-clipboard` for Wayland clipboard
- **macOS**: Uses built-in `pbpaste`
- **Windows**: Uses PowerShell clipboard commands

### **Build Tools**
- **Linux**: `build-essential`, `gcc`, `make`, `pkg-config`
- **macOS**: Xcode command line tools
- **Windows**: Visual Studio Build Tools (if needed)

### **System Libraries**
- SSL/TLS libraries for secure connections
- Compression libraries for data handling
- Terminal libraries for interactive features
- Development headers for Perl modules

## Dependency Management

ZChat categorizes dependencies into three types:

### **Core Dependencies** (Required)
These are essential for ZChat to work:
- HTTP client for API communication
- JSON and YAML processing
- Command-line parsing
- File operations

### **Optional Dependencies** (Enhanced Features)
These add extra functionality but aren't required:
- **Image::Magick**: Image processing for `--img` feature
- **Text::Xslate**: Advanced template features
- **Term::ReadLine::Gnu**: Enhanced command-line editing
- **Term::Size**: Dynamic terminal formatting

### **System Dependencies** (Platform-Specific)
These are automatically installed based on your platform:
- Clipboard tools
- Build tools
- Development libraries

## Platform-Specific Features

### **WSL2 Users**
- Automatic X11 clipboard detection
- WSLg compatibility
- Windows integration notes
- Performance optimization tips

### **Linux Users**
- Automatic package manager detection (apt, yum, pacman, etc.)
- Display server detection (X11 vs Wayland)
- Distribution-specific optimizations

### **macOS Users**
- Homebrew integration
- Apple Silicon compatibility
- Native clipboard support
- Terminal.app optimization

### **Windows Users**
- PowerShell integration
- Native Windows clipboard
- WSL2 compatibility
- Windows Terminal support

## Manual Override

If automatic detection doesn't work perfectly, you can:

### **Check Your Environment**
```bash
# Run the dependency detector
./install/dependency-detector.sh

# Check platform-specific dependencies
./install/platform-dependencies.sh
```

### **Install Missing Tools**
```bash
# Ubuntu/Debian
sudo apt-get install xclip build-essential

# CentOS/RHEL
sudo yum install xclip gcc make

# macOS
brew install xclip

# Arch Linux
sudo pacman -S xclip base-devel
```

### **Force Specific Installation**
```bash
# Force minimal installation
./install.sh --minimal

# Force standard installation
./install.sh --standard

# Repair installation
./install.sh --repair
```

## Troubleshooting

### **Clipboard Not Working**
- **WSL2**: Ensure WSLg is enabled and `xclip` is installed
- **Linux**: Check if you're using X11 or Wayland
- **macOS**: Verify `pbpaste` is available
- **Windows**: Ensure PowerShell is available

### **Build Failures**
- **Missing headers**: Install development packages
- **Compiler issues**: Update build tools
- **Library conflicts**: Check for conflicting versions

### **Terminal Issues**
- **Color problems**: Check `$TERM` and `$COLORTERM`
- **Size detection**: Verify `tput` is available
- **Remote terminals**: May have limited capabilities

## Benefits

The platform system provides:

- **Automatic Setup**: No manual configuration needed
- **Optimal Performance**: Platform-specific optimizations
- **Better Compatibility**: Handles edge cases and environments
- **Clear Feedback**: Detailed reports and recommendations
- **Easy Troubleshooting**: Platform-specific guidance

## Learn More

- [Installation Guide](INSTALLATION.md) - Detailed installation instructions
- [Dependencies](DEPENDENCIES.md) - Complete dependency information
- [Health Check](health-check.pl) - Diagnose your installation

---

*The platform system ensures ZChat works great on your system, automatically adapting to your environment for the best possible experience.*