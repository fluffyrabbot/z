@echo off
REM ZChat Windows Batch Installer Wrapper
REM This batch file runs the PowerShell installer

echo ZChat Windows Installer
echo ======================
echo.

REM Check if PowerShell is available
powershell -Command "Get-Host" >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: PowerShell is not available on this system.
    echo Please install PowerShell or use the bash installer with WSL2/Git Bash.
    echo.
    echo Alternative installation methods:
    echo 1. Install WSL2 and run: bash install.sh
    echo 2. Install Git Bash and run: bash install.sh
    echo 3. Install PowerShell and run: powershell -ExecutionPolicy Bypass -File install.ps1
    pause
    exit /b 1
)

REM Check execution policy
echo Checking PowerShell execution policy...
powershell -Command "Get-ExecutionPolicy" | findstr /i "restricted" >nul
if %errorlevel% equ 0 (
    echo.
    echo WARNING: PowerShell execution policy is restricted.
    echo You may need to run PowerShell as Administrator and set execution policy:
    echo   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    echo.
    echo Or run the installer with bypass:
    echo   powershell -ExecutionPolicy Bypass -File install.ps1
    echo.
    pause
)

REM Run PowerShell installer
echo Running PowerShell installer...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*

if %errorlevel% equ 0 (
    echo.
    echo Installation completed successfully!
    echo You may need to restart your terminal for changes to take effect.
) else (
    echo.
    echo Installation failed. Please check the error messages above.
)

echo.
pause