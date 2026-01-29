# Windows Build Guide

## Prerequisites

Before building on Windows, you need to install the following tools:

### 1. Rust and Cargo

Install Rust using rustup:

```powershell
# Download and run rustup installer
Invoke-WebRequest -Uri "https://win.rustup.rs/x86_64" -OutFile "$env:TEMP\rustup-init.exe"
& "$env:TEMP\rustup-init.exe" -y --default-toolchain stable

# Refresh your PATH (restart terminal or run):
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","User") + ";" + [System.Environment]::GetEnvironmentVariable("Path","Machine")

# Verify installation
cargo --version
```

### 2. Visual Studio Build Tools (C++)

Rust on Windows requires the MSVC linker. Install Visual Studio Build Tools:

1. Download from: https://visualstudio.microsoft.com/downloads/
2. Run the installer and select "Desktop development with C++" workload
3. Make sure to include:
   - MSVC v143 - VS 2022 C++ x64/x86 build tools
   - Windows 10/11 SDK

Alternatively, you can use the Visual Studio Installer command line:

```powershell
# Download Visual Studio Build Tools installer
winget install Microsoft.VisualStudio.2022.BuildTools --override "--wait --passive --add Microsoft.VisualStudio.Workload.VCTools;includeRecommended"
```

### 3. Node.js

Install Node.js LTS from: https://nodejs.org/

Verify installation:
```powershell
node --version
npm --version
```

## Building the Application

### 1. Prepare Embedded Python

```powershell
# Run the preparation script
.\prepare-embedded-python.ps1
```

This will:
- Download Python 3.12.8 embedded distribution
- Install required Python packages (pdfplumber, openpyxl, Pillow, pdfminer.six)
- Set up the Python environment in `src-tauri/resources/python`

### 2. Build the Application

```powershell
# Run the build script
.\build.ps1
```

Or manually:

```powershell
cd pdf2excel
npm install
npm run tauri:build
```

### 3. Locate the Build Output

After successful build, the installer will be located at:

```
pdf2excel\src-tauri\target\release\bundle\msi\
```

Look for `pdf2excel_0.1.0_x64_en-US.msi` (version may vary)

## Troubleshooting

### Error: linker `link.exe` not found

**Solution:** Install Visual Studio Build Tools with C++ workload (see Prerequisites section 2).

### Error: cargo not found

**Solution:** Install Rust using rustup (see Prerequisites section 1).

### Error: Embedded Python not found

**Solution:** Run `.\prepare-embedded-python.ps1` to set up the Python environment.

### Build fails with MSVC errors

**Solution:** Make sure you have the correct version of Visual Studio Build Tools installed and your PATH includes the MSVC bin directory. You may need to restart your terminal after installation.

## Quick Start

If you have all prerequisites installed:

```powershell
# 1. Prepare Python environment
.\prepare-embedded-python.ps1

# 2. Build the application
.\build.ps1

# 3. Install the MSI file from pdf2excel\src-tauri\target\release\bundle\msi\
```

## Development

For development mode (faster rebuilds):

```powershell
cd pdf2excel
npm run tauri:dev
```