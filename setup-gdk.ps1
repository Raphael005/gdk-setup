#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Microsoft GDK Development Environment Setup Script
.DESCRIPTION
    Installs Visual Studio 2022, GDK, and development tools for Xbox/PC game development
.PARAMETER VerifyOnly
    Skip installation and only verify existing setup
.PARAMETER SkipRestart
    Skip the restart prompt at the end
.EXAMPLE
    .\setup-gdk.ps1
.EXAMPLE
    .\setup-gdk.ps1 -VerifyOnly
#>

param(
    [switch]$VerifyOnly,
    [switch]$SkipRestart
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Configuration
$Config = @{
    GdkPath = "C:\Program Files (x86)\Microsoft GDK"
    VsPath  = "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community"
    LogFile = "$env:USERPROFILE\gdk-setup.log"
}

# Logging function
function Write-Log {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $Config.LogFile -Value "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        "INFO"    { Write-Host $Message }
        "SUCCESS" { Write-Host "  ✓ $Message" -ForegroundColor Green }
        "WARNING" { Write-Host "  ! $Message" -ForegroundColor Yellow }
        "ERROR"   { Write-Host "  ✗ $Message" -ForegroundColor Red }
        "STEP"    { Write-Host "`n$Message" -ForegroundColor Yellow }
        "HEADER"  { Write-Host "`n$Message" -ForegroundColor Cyan }
    }
}

# Check if package is installed
function Test-WingetPackage {
    param($PackageId)
    $result = winget list --id $PackageId 2>$null
    return $result -match $PackageId
}

# Install package with retry
function Install-WingetPackage {
    param(
        [string]$PackageId,
        [string]$Name,
        [string]$Override = $null,
        [int]$MaxRetries = 2
    )
    
    if (Test-WingetPackage $PackageId) {
        Write-Log "$Name already installed" "SUCCESS"
        return $true
    }
    
    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            Write-Log "Installing $Name (attempt $i/$MaxRetries)..."
            
            $argList = "install $PackageId --silent --accept-package-agreements --accept-source-agreements"
            if ($Override) { $argList += " --override `"$Override`"" }
            
            $proc = Start-Process -FilePath "winget" -ArgumentList $argList -Wait -PassThru -NoNewWindow
            
            if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq -1978335189) {
                Write-Log "$Name installed" "SUCCESS"
                return $true
            }
        } catch {
            Write-Log "Attempt $i failed: $_" "WARNING"
        }
        Start-Sleep -Seconds 3
    }
    
    Write-Log "Failed to install $Name" "ERROR"
    return $false
}

# Verification function
function Test-Installation {
    Write-Log "=== Installation Verification ===" "HEADER"
    
    $allPassed = $true
    
    # Check GDK
    if (Test-Path $Config.GdkPath) {
        Write-Log "GDK installed" "SUCCESS"
        Get-ChildItem $Config.GdkPath -Directory | ForEach-Object {
            Write-Host "      - $($_.Name)" -ForegroundColor Gray
        }
    } else {
        Write-Log "GDK not found" "ERROR"
        $allPassed = $false
    }
    
    # Check Visual Studio
    if (Test-Path $Config.VsPath) {
        Write-Log "Visual Studio 2022 Community installed" "SUCCESS"
        $vcTools = Test-Path "$($Config.VsPath)\VC\Tools\MSVC"
        Write-Host "      - C++ tools: $(if ($vcTools) { 'installed' } else { 'not found' })" -ForegroundColor Gray
    } else {
        Write-Log "Visual Studio 2022 not found" "ERROR"
        $allPassed = $false
    }
    
    # Check Git
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Log "Git $(git --version)" "SUCCESS"
    } else {
        Write-Log "Git not found" "WARNING"
    }
    
    # Check VS Code
    if (Get-Command code -ErrorAction SilentlyContinue) {
        Write-Log "VS Code installed" "SUCCESS"
    } else {
        Write-Log "VS Code not in PATH (restart may be needed)" "WARNING"
    }
    
    # Check Windows Terminal
    if (Get-AppxPackage -Name Microsoft.WindowsTerminal -ErrorAction SilentlyContinue) {
        Write-Log "Windows Terminal installed" "SUCCESS"
    } else {
        Write-Log "Windows Terminal not found" "WARNING"
    }
    
    return $allPassed
}

# Main installation function
function Install-GdkEnvironment {
    Write-Log "=== GDK Environment Setup ===" "HEADER"
    Write-Log "Log file: $($Config.LogFile)"
    Write-Host "Estimated time: 15-30 minutes`n"
    
    $totalSteps = 6
    $currentStep = 0
    
    # Step 1: Update sources
    $currentStep++
    Write-Log "[$currentStep/$totalSteps] Updating package sources..." "STEP"
    try {
        winget source update 2>$null | Out-Null
        Write-Log "Sources updated" "SUCCESS"
    } catch {
        Write-Log "Could not update sources, continuing..." "WARNING"
    }
    
    # Step 2: Visual Studio 2022
    $currentStep++
    Write-Log "[$currentStep/$totalSteps] Installing Visual Studio 2022..." "STEP"
    Write-Host "  This may take 10-20 minutes..." -ForegroundColor Gray
    
    $vsOverride = "--add Microsoft.VisualStudio.Workload.NativeDesktop " +
                  "--add Microsoft.VisualStudio.Workload.NativeGame " +
                  "--add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 " +
                  "--add Microsoft.VisualStudio.Component.Windows11SDK.22621 " +
                  "--includeRecommended --quiet --wait"
    
    Install-WingetPackage -PackageId "Microsoft.VisualStudio.2022.Community" -Name "Visual Studio 2022" -Override $vsOverride
    
    # Step 3: GDK
    $currentStep++
    Write-Log "[$currentStep/$totalSteps] Installing Microsoft GDK..." "STEP"
    Install-WingetPackage -PackageId "Microsoft.Gaming.GDK" -Name "GDK"
    
    # Step 4: Git
    $currentStep++
    Write-Log "[$currentStep/$totalSteps] Installing Git..." "STEP"
    Install-WingetPackage -PackageId "Git.Git" -Name "Git"
    
    # Step 5: Additional tools
    $currentStep++
    Write-Log "[$currentStep/$totalSteps] Installing additional tools..." "STEP"
    Install-WingetPackage -PackageId "Microsoft.WindowsTerminal" -Name "Windows Terminal"
    Install-WingetPackage -PackageId "Microsoft.VisualStudioCode" -Name "VS Code"
    
    # Step 6: Verify
    $currentStep++
    Write-Log "[$currentStep/$totalSteps] Verifying installation..." "STEP"
    $verified = Test-Installation
    
    # Create post-restart verification script
    @'
# Run this after restart to verify installation
Set-ExecutionPolicy Bypass -Scope Process -Force
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
& "$scriptPath\setup-gdk.ps1" -VerifyOnly
Read-Host "`nPress Enter to close"
'@ | Out-File "$env:USERPROFILE\verify-gdk.ps1" -Encoding UTF8
    
    # Final summary
    Write-Log "=== Setup Complete ===" "HEADER"
    Write-Host @"

NEXT STEPS:
-----------
1. Restart the VM to complete setup
2. Run verify-gdk.ps1 to confirm installation
3. Open Visual Studio 2022
4. Go to: Extensions > Manage Extensions
5. Search for "GDK Development" and install it
6. Restart Visual Studio
7. Create new project using a GDK template
8. Build and run to verify everything works

USEFUL COMMANDS:
----------------
  Verify setup:     .\setup-gdk.ps1 -VerifyOnly
  View log:         Get-Content $($Config.LogFile)
  GDK docs:         https://aka.ms/gamedevdocs
  GDK samples:      https://github.com/microsoft/Xbox-GDK-Samples

"@ -ForegroundColor White
    
    return $verified
}

# Entry point
Write-Host ""
Write-Host "  Microsoft GDK Development Environment Setup" -ForegroundColor White
Write-Host "  ===========================================" -ForegroundColor Gray
Write-Host ""

if ($VerifyOnly) {
    $result = Test-Installation
    if ($result) {
        Write-Host "`n  Environment is ready for GDK development!" -ForegroundColor Green
    } else {
        Write-Host "`n  Some components are missing. Run setup without -VerifyOnly to install." -ForegroundColor Yellow
    }
    exit $(if ($result) { 0 } else { 1 })
}

# Run installation
$success = Install-GdkEnvironment

# Handle restart
if (-not $SkipRestart) {
    Write-Host ""
    $restart = Read-Host "Restart now to complete setup? (y/n)"
    if ($restart -eq 'y') {
        Write-Log "Restarting in 5 seconds..." "INFO"
        Start-Sleep -Seconds 5
        Restart-Computer -Force
    } else {
        Write-Host "`nRemember to restart before using Visual Studio." -ForegroundColor Yellow
    }
}

exit $(if ($success) { 0 } else { 1 })
