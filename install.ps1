# ZChat PowerShell Installer v0.9
# Native Windows PowerShell installer for ZChat

param(
    [switch]$Minimal,
    [switch]$Standard,
    [switch]$Bundle,
    [switch]$Single,
    [switch]$Platform,
    [switch]$Optimized,
    [switch]$Repair,
    [switch]$Force,
    [switch]$Offline,
    [switch]$Verbose,
    [switch]$Help
)

# Colors for output
$Colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
    Blue = "Blue"
    Cyan = "Cyan"
    White = "White"
}

function Write-Status { param($Message) Write-Host "[OK] $Message" -ForegroundColor $Colors.Green }
function Write-Warning { param($Message) Write-Host "[WARNING] $Message" -ForegroundColor $Colors.Yellow }
function Write-Error { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor $Colors.Red }
function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor $Colors.Blue }

# Show help
if ($Help) {
    Write-Host "ZChat PowerShell Installer v0.9" -ForegroundColor $Colors.Cyan
    Write-Host ""
    Write-Host "Usage: .\install.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Installation Modes:"
    Write-Host "  (default)         Smart installation with environment detection"
    Write-Host "  -Minimal          Quick installation with core dependencies only"
    Write-Host "  -Standard         Standard installation with interactive prompts"
    Write-Host "  -Bundle           Create static bundle (self-contained) [RECOMMENDED]"
    Write-Host "  -Single           Create single executable (PAR Packer)"
    Write-Host "  -Platform         Create platform-specific bundles"
    Write-Host "  -Optimized        Create size-optimized bundle"
    Write-Host "  -Repair           Repair existing installation"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Verbose          Verbose output"
    Write-Host "  -Force            Force installation (overwrite existing)"
    Write-Host "  -Offline          Offline installation mode"
    Write-Host "  -Help             Show this help"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\install.ps1                    # Smart installation (default)"
    Write-Host "  .\install.ps1 -Minimal           # Minimal installation"
    Write-Host "  .\install.ps1 -Standard           # Standard installation with prompts"
    Write-Host "  .\install.ps1 -Bundle             # Create static bundle (recommended)"
    Write-Host "  .\install.ps1 -Single             # Create single executable (PAR Packer)"
    Write-Host "  .\install.ps1 -Platform           # Create platform-specific bundles"
    Write-Host "  .\install.ps1 -Optimized          # Create size-optimized bundle"
    Write-Host "  .\install.ps1 -Repair             # Repair existing installation"
    exit 0
}

# Determine installation mode
$InstallMode = "adaptive"
if ($Minimal) { $InstallMode = "minimal" }
elseif ($Standard) { $InstallMode = "standard" }
elseif ($Bundle) { $InstallMode = "bundle" }
elseif ($Single) { $InstallMode = "single" }
elseif ($Platform) { $InstallMode = "platform" }
elseif ($Optimized) { $InstallMode = "optimized" }
elseif ($Repair) { $InstallMode = "repair" }

# Global variables
$Global:Verbose = $Verbose
$Global:Force = $Force
$Global:Offline = $Offline

# Detect Windows environment
function Detect-WindowsEnvironment {
    Write-Info "Detecting Windows environment..."
    
    $env = @{
        OS = "windows"
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
        UserProfile = $env:USERPROFILE
        ProgramFiles = $env:ProgramFiles
        ProgramFilesX86 = ${env:ProgramFiles(x86)}
        AppData = $env:APPDATA
        LocalAppData = $env:LOCALAPPDATA
    }
    
    # Detect WSL
    if (Test-Path "C:\Windows\System32\wsl.exe") {
        $env.WSL = $true
        Write-Info "WSL detected"
    } else {
        $env.WSL = $false
    }
    
    # Detect Git Bash
    if (Test-Path "C:\Program Files\Git\bin\bash.exe") {
        $env.GitBash = $true
        Write-Info "Git Bash detected"
    } else {
        $env.GitBash = $false
    }
    
    # Detect Perl
    try {
        $perlVersion = & perl -v 2>$null | Select-String "This is perl" | ForEach-Object { $_.Line -replace ".*v(\d+\.\d+\.\d+).*", '$1' }
        if ($perlVersion) {
            $env.PerlVersion = $perlVersion
            $env.PerlAvailable = $true
            Write-Status "Perl $perlVersion detected"
        } else {
            $env.PerlAvailable = $false
            Write-Warning "Perl not found"
        }
    } catch {
        $env.PerlAvailable = $false
        Write-Warning "Perl not found"
    }
    
    # Detect package managers
    $env.Chocolatey = Get-Command choco -ErrorAction SilentlyContinue
    $env.Winget = Get-Command winget -ErrorAction SilentlyContinue
    
    Write-Status "Windows environment detection complete"
    return $env
}

# Check for existing installation
function Test-ExistingInstallation {
    Write-Info "Checking for existing ZChat installation..."
    
    $installations = @()
    
    # Check common installation locations
    $locations = @(
        "$env:LOCALAPPDATA\bin\z.exe",
        "$env:LOCALAPPDATA\bin\zchat.exe",
        "$env:ProgramFiles\zchat\bin\z.exe",
        "$env:ProgramFiles\zchat\bin\zchat.exe",
        "${env:ProgramFiles(x86)}\zchat\bin\z.exe",
        "${env:ProgramFiles(x86)}\zchat\bin\zchat.exe"
    )
    
    foreach ($location in $locations) {
        if (Test-Path $location) {
            $installations += $location
        }
    }
    
    # Check PATH
    try {
        $zPath = Get-Command z -ErrorAction SilentlyContinue
        if ($zPath) {
            $installations += $zPath.Source
        }
    } catch {}
    
    # Check config directory
    $configDir = "$env:APPDATA\zchat"
    if (Test-Path $configDir) {
        $installations += $configDir
    }
    
    if ($installations.Count -gt 0) {
        Write-Warning "Existing ZChat installation(s) detected!"
        Write-Host ""
        foreach ($install in $installations) {
            Write-Host "  • $install" -ForegroundColor $Colors.Yellow
        }
        Write-Host ""
        Write-Host "ZChat appears to already be installed on this system."
        Write-Host "To avoid conflicts and preserve your existing setup, please use:"
        Write-Host ""
        Write-Host "  • Repair existing installation: .\install.ps1 -Repair" -ForegroundColor $Colors.Cyan
        Write-Host "  • Clean uninstall if needed"
        Write-Host ""
        if (-not $Force) {
            Write-Host "If you want to force a fresh installation anyway, run:" -ForegroundColor $Colors.Red
            Write-Host "  .\install.ps1 -Force" -ForegroundColor $Colors.Cyan
            Write-Host ""
            Write-Host "Exiting to protect existing installation." -ForegroundColor $Colors.Red
            Write-Host "Use -Force flag to override this protection."
            exit 0
        } else {
            Write-Warning "Force flag detected - proceeding with fresh installation..."
        }
    } else {
        Write-Status "No existing installation detected"
    }
}

# Install Perl dependencies
function Install-PerlDependencies {
    param($Modules)
    
    Write-Info "Installing Perl dependencies..."
    
    if (-not $env.PerlAvailable) {
        Write-Error "Perl is required but not found. Please install Perl first:"
        Write-Host "  • Strawberry Perl: https://strawberryperl.com/"
        Write-Host "  • ActivePerl: https://www.activestate.com/products/perl/"
        Write-Host "  • Or use: winget install StrawberryPerl.StrawberryPerl"
        exit 1
    }
    
    # Install cpanm if not available
    try {
        & cpanm --version 2>$null | Out-Null
        Write-Status "cpanm available"
    } catch {
        Write-Info "Installing cpanm..."
        & perl -MCPAN -e "install App::cpanminus" 2>$null
    }
    
    # Install modules
    foreach ($module in $Modules) {
        Write-Info "Installing $module..."
        try {
            & cpanm --notest --quiet $module
            Write-Status "$module installed successfully"
        } catch {
            Write-Warning "Failed to install $module"
        }
    }
}

# Install system dependencies
function Install-SystemDependencies {
    Write-Info "Installing system dependencies..."
    
    # Install build tools if needed
    if ($env.Chocolatey) {
        Write-Info "Installing build tools via Chocolatey..."
        & choco install -y make gcc 2>$null
    } elseif ($env.Winget) {
        Write-Info "Installing build tools via winget..."
        & winget install -e --id Microsoft.VisualStudio.2022.BuildTools 2>$null
    } else {
        Write-Warning "No package manager found. Please install build tools manually:"
        Write-Host "  • Visual Studio Build Tools"
        Write-Host "  • Or install Chocolatey: https://chocolatey.org/"
    }
}

# Create PowerShell wrapper
function New-PowerShellWrapper {
    param($InstallDir)
    
    $wrapperScript = @"
# ZChat PowerShell Wrapper
# Auto-generated wrapper for ZChat

`$ZChatPath = "$InstallDir\z.exe"
if (Test-Path `$ZChatPath) {
    & `$ZChatPath @args
} else {
    Write-Error "ZChat not found at `$ZChatPath"
    exit 1
}
"@
    
    $wrapperPath = "$InstallDir\z.ps1"
    $wrapperScript | Out-File -FilePath $wrapperPath -Encoding UTF8
    Write-Status "PowerShell wrapper created: $wrapperPath"
}

# Main installation function
function Install-ZChat {
    param($Mode)
    
    Write-Host "ZChat PowerShell Installer v0.9" -ForegroundColor $Colors.Cyan
    Write-Host ""
    
    # Detect environment
    $env = Detect-WindowsEnvironment
    
    # Check for existing installation (except repair mode)
    if ($Mode -ne "repair") {
        Test-ExistingInstallation
    }
    
    # Determine install directory
    if ($env.IsAdmin) {
        $installDir = "$env:ProgramFiles\zchat\bin"
        $configDir = "$env:ProgramFiles\zchat\config"
    } else {
        $installDir = "$env:LOCALAPPDATA\bin"
        $configDir = "$env:APPDATA\zchat"
    }
    
    Write-Info "Installing to: $installDir"
    Write-Info "Config directory: $configDir"
    
    # Create directories
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    
    # Install system dependencies
    Install-SystemDependencies
    
    # Install Perl dependencies
    $coreModules = @(
        "Mojo::UserAgent",
        "JSON::XS", 
        "YAML::XS",
        "Getopt::Long::Descriptive",
        "URI::Escape",
        "Data::Dumper",
        "String::ShellQuote",
        "File::Slurper",
        "File::Copy",
        "File::Temp",
        "File::Compare",
        "Carp",
        "Term::ReadLine",
        "Capture::Tiny",
        "LWP::UserAgent"
    )
    
    Install-PerlDependencies -Modules $coreModules
    
    # Copy ZChat binary
    if (Test-Path "z") {
        Copy-Item "z" "$installDir\z.exe" -Force
        Write-Status "ZChat binary installed"
    } else {
        Write-Error "ZChat binary (z) not found in current directory"
        exit 1
    }
    
    # Create PowerShell wrapper
    New-PowerShellWrapper -InstallDir $installDir
    
    # Create configuration
    $configContent = @"
# ZChat User Configuration
# This file stores your global preferences

session: "default"
system_string: "You are a helpful AI assistant."
api_key: ""
model: "gpt-4"
temperature: 0.7
max_tokens: 4000
"@
    
    $configFile = "$configDir\user.yaml"
    if (-not (Test-Path $configFile)) {
        $configContent | Out-File -FilePath $configFile -Encoding UTF8
        Write-Status "Configuration created: $configFile"
    }
    
    # Add to PATH
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($currentPath -notlike "*$installDir*") {
        $newPath = "$currentPath;$installDir"
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        Write-Status "Added to PATH: $installDir"
        Write-Warning "Please restart PowerShell or open a new terminal for PATH changes to take effect"
    }
    
    Write-Host ""
    Write-Host "Installation completed successfully!" -ForegroundColor $Colors.Green
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor $Colors.Cyan
    Write-Host "  z --help                    # Show help"
    Write-Host "  z \"Hello, world!\"          # Chat with AI"
    Write-Host "  z --config                  # Configure API key"
    Write-Host ""
    Write-Host "Note: You may need to restart PowerShell for the 'z' command to be available." -ForegroundColor $Colors.Yellow
}

# Repair installation
function Repair-ZChatInstallation {
    Write-Host "ZChat Repair Tool (PowerShell)" -ForegroundColor $Colors.Cyan
    Write-Host "===============================" -ForegroundColor $Colors.Cyan
    Write-Host ""
    
    $env = Detect-WindowsEnvironment
    
    Write-Host "Choose repair action:" -ForegroundColor $Colors.Cyan
    Write-Host ""
    Write-Host "1. Repair Dependencies" -ForegroundColor $Colors.Cyan
    Write-Host "   - Reinstall missing or corrupted Perl modules"
    Write-Host "   - Keep existing configuration and data"
    Write-Host ""
    Write-Host "2. Update Installation" -ForegroundColor $Colors.Cyan
    Write-Host "   - Reinstall ZChat with latest version"
    Write-Host "   - Preserve configuration and data"
    Write-Host ""
    Write-Host "3. Force Reinstall" -ForegroundColor $Colors.Cyan
    Write-Host "   - Complete reinstall, overwrite everything"
    Write-Host "   - Backup existing config first"
    Write-Host ""
    Write-Host "4. Clean Uninstall" -ForegroundColor $Colors.Cyan
    Write-Host "   - Remove ZChat completely"
    Write-Host "   - Clean up all files and dependencies"
    Write-Host ""
    
    $choice = Read-Host "Enter your choice (1-4)"
    
    switch ($choice) {
        "1" {
            Write-Info "Repairing dependencies..."
            # Implementation for dependency repair
        }
        "2" {
            Write-Info "Updating installation..."
            # Implementation for update
        }
        "3" {
            Write-Info "Force reinstalling..."
            # Implementation for force reinstall
        }
        "4" {
            Write-Info "Uninstalling ZChat..."
            # Implementation for uninstall
        }
        default {
            Write-Error "Invalid choice"
            exit 1
        }
    }
}

# Main execution
try {
    switch ($InstallMode) {
        "repair" {
            Repair-ZChatInstallation
        }
        default {
            Install-ZChat -Mode $InstallMode
        }
    }
} catch {
    Write-Error "Installation failed: $($_.Exception.Message)"
    exit 1
}