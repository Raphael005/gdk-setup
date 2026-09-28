# GDK Development Environment Setup

Automated setup script for Microsoft Game Development Kit (GDK) on Windows.

## Prerequisites

- Windows 10/11 (VM or physical machine)
- Administrator access
- Internet connection
- ~30GB free disk space

## Quick Start

1. Copy `setup-gdk.ps1` to your Windows machine
2. Open PowerShell as Administrator
3. Run:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\setup-gdk.ps1
```

4. Wait 15-30 minutes for installation
5. Restart when prompted
6. Run verification after restart

## What Gets Installed

| Component | Purpose |
|-----------|---------|
| Visual Studio 2022 Community | IDE with C++ and Game development workloads |
| Microsoft GDK | Game Development Kit for Xbox/PC |
| Git | Version control |
| Windows Terminal | Modern terminal |
| VS Code | Lightweight editor |

## Usage

### Full Installation

```powershell
.\setup-gdk.ps1
```

### Verify Installation

```powershell
.\setup-gdk.ps1 -VerifyOnly
```

### Skip Restart Prompt

```powershell
.\setup-gdk.ps1 -SkipRestart
```

## Post-Installation Steps

1. **Install GDK Extension**
   - Open Visual Studio 2022
   - Go to **Extensions > Manage Extensions**
   - Search for "GDK Development"
   - Install and restart Visual Studio

2. **Create a Test Project**
   - File > New > Project
   - Select a GDK template
   - Build and run

## Verification Checklist

After running `-VerifyOnly`, confirm:

- [ ] GDK installed at `C:\Program Files (x86)\Microsoft GDK`
- [ ] Visual Studio 2022 with C++ tools
- [ ] Git available in PATH
- [ ] Windows Terminal installed

## Troubleshooting

### Script won't run

**Error:** "Running scripts is disabled on this system"

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```

### Script requires administrator

**Error:** "#Requires -RunAsAdministrator"

1. Right-click PowerShell
2. Select "Run as Administrator"
3. Navigate to the script location and run again

### Installation fails

Check the log file:

```powershell
Get-Content $env:USERPROFILE\gdk-setup.log
```

### Winget not found

**Error:** "winget: The term 'winget' is not recognized"

1. Open Microsoft Store
2. Search for "App Installer"
3. Install or update it
4. Restart PowerShell

Alternatively:
```powershell
Invoke-WebRequest -Uri https://aka.ms/getwinget -OutFile winget.msixbundle
Add-AppxPackage winget.msixbundle
```

### Visual Studio installation hangs

**Symptom:** Script stuck on "Installing Visual Studio 2022"

- Visual Studio installation can take 15-30 minutes
- Check Task Manager for `vs_installer.exe` activity
- If no progress after 45 minutes, cancel and run manually:

```powershell
winget install Microsoft.VisualStudio.2022.Community --interactive
```

### Visual Studio workloads missing

**Symptom:** No GDK templates available

1. Open Visual Studio Installer
2. Click "Modify" on VS 2022 Community
3. Check these workloads:
   - Desktop development with C++
   - Game development with C++
4. Click "Modify" and wait for completion

### GDK not found after install

**Symptom:** Verification shows "GDK not found"

1. Restart the machine
2. Run verification again:
   ```powershell
   .\setup-gdk.ps1 -VerifyOnly
   ```
3. If still missing, install manually:
   ```powershell
   winget install Microsoft.Gaming.GDK
   ```

### GDK extension not appearing in Visual Studio

1. Ensure Visual Studio is fully closed
2. Go to **Extensions > Manage Extensions**
3. Click **Online** tab
4. Search for "GDK Development"
5. Install and restart Visual Studio

### Build errors after setup

**Error:** "Windows SDK not found"

```powershell
winget install Microsoft.WindowsSDK.10.0.22621
```

**Error:** "Cannot find C++ compiler"

1. Open Visual Studio Installer
2. Ensure "MSVC v143 - VS 2022 C++ x64/x86 build tools" is checked
3. Modify installation

### Network/download failures

**Error:** "Download failed" or "Connection timed out"

1. Check internet connection
2. Disable VPN temporarily
3. Try again:
   ```powershell
   winget source update
   .\setup-gdk.ps1
   ```

### Disk space errors

**Error:** "Not enough disk space"

- Visual Studio requires ~15GB
- GDK requires ~5GB
- Free up space or expand VM disk

Check available space:
```powershell
Get-PSDrive C | Select-Object Free, Used
```

### Permission denied errors

**Error:** "Access to path denied"

1. Ensure running as Administrator
2. Check antivirus isn't blocking installers
3. Temporarily disable Windows Defender:
   ```powershell
   Set-MpPreference -DisableRealtimeMonitoring $true
   # Run setup, then re-enable:
   Set-MpPreference -DisableRealtimeMonitoring $false
   ```

## File Locations

| Item | Path |
|------|------|
| GDK | `C:\Program Files (x86)\Microsoft GDK` |
| Visual Studio | `C:\Program Files\Microsoft Visual Studio\2022\Community` |
| Setup log | `%USERPROFILE%\gdk-setup.log` |
| Verify script | `%USERPROFILE%\verify-gdk.ps1` |

## Resources

- [GDK Documentation](https://aka.ms/gamedevdocs)
- [GDK Samples](https://github.com/microsoft/Xbox-GDK-Samples)
- [GDK Releases](https://github.com/microsoft/GDK/releases)
- [Visual Studio GDK Extension](https://aka.ms/gdktemplates)

## Transferring to Windows VM

### Option 1: Remote Desktop drag-and-drop
1. Connect via Microsoft Remote Desktop
2. Drag `setup-gdk.ps1` into the VM window

### Option 2: Cloud storage
1. Upload to OneDrive/Google Drive/Dropbox
2. Download on the VM

### Option 3: GitHub Gist
1. Create a gist with the script
2. Download raw file on the VM

## License

This setup script is provided as-is for development purposes.
