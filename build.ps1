param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("windows")]
    [string]$Target = "windows"
)

$ErrorActionPreference = "Stop"

$ROOT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$APP_DIR = Join-Path $ROOT_DIR "pdf2excel"
$RESOURCES_DIR = Join-Path $APP_DIR "src-tauri\resources"
$PYTHON_DIR = Join-Path $RESOURCES_DIR "python"

function Show-Usage {
    Write-Host @"
Usage: .\build.ps1 [windows]

Builds the Tauri app and verifies the embedded Python runtime + deps exist.

Env:
  SKIP_NPM_INSTALL=1   Skip npm install if node_modules is missing.
"@
}

function Test-NodeModules {
    $nodeModulesPath = Join-Path $APP_DIR "node_modules"
    if (-not (Test-Path $nodeModulesPath)) {
        if ($env:SKIP_NPM_INSTALL -eq "1") {
            throw "node_modules is missing. Run npm install first."
        }
        Write-Host "node_modules missing, running npm install..."
        Push-Location $APP_DIR
        npm install
        Pop-Location
    }
}

function Test-RustToolchain {
    if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
        throw "Rust/Cargo not found. Please install Rust from https://rustup.rs/"
    }
    
    if (-not (Get-Command link -ErrorAction SilentlyContinue)) {
        Write-Host "MSVC linker (link.exe) not found in PATH. Attempting to auto-load Visual Studio environment..."
        
        # 查找 Visual Studio 安装路径
        $vsWherePath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
        if (-not (Test-Path $vsWherePath)) {
            throw "Visual Studio not found. Please install Visual Studio Build Tools with C++ workload from https://visualstudio.microsoft.com/downloads/"
        }
        
        $vsInstallPath = & $vsWherePath -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2>$null
        if (-not $vsInstallPath) {
            throw "Visual Studio Build Tools with C++ workload not found. Please install it from https://visualstudio.microsoft.com/downloads/"
        }
        
        $vcvarsPath = Join-Path $vsInstallPath "VC\Auxiliary\Build\vcvars64.bat"
        if (-not (Test-Path $vcvarsPath)) {
            throw "vcvars64.bat not found at: $vcvarsPath"
        }
        
        Write-Host "Loading Visual Studio environment from: $vcvarsPath"
        
        # 加载 VS 环境变量
        cmd /c "`"$vcvarsPath`" && set" | ForEach-Object {
            if ($_ -match '^([^=]+)=(.*)$') {
                $name = $matches[1]
                $value = $matches[2]
                [Environment]::SetEnvironmentVariable($name, $value, "Process")
            }
        }
        
        # 再次检查 link.exe
        if (-not (Get-Command link -ErrorAction SilentlyContinue)) {
            throw "MSVC linker (link.exe) still not found after loading VS environment. Please run this script in 'x64 Native Tools Command Prompt for VS'"
        }
        
        Write-Host "Visual Studio environment loaded successfully."
    }
}

function Test-PythonEnv {
    param([string]$PythonBin)
    
    if (-not (Test-Path $PythonBin)) {
        throw "Embedded Python not found at: $PythonBin"
    }
    
    $testScript = "import pdfplumber, openpyxl, pdfminer, PIL"
    & $PythonBin -c $testScript
    if ($LASTEXITCODE -ne 0) {
        throw "Python dependencies check failed for: $PythonBin"
    }
}

function Build-Windows {
    $pythonBin = Join-Path $PYTHON_DIR "python.exe"

    if (-not (Test-Path $PYTHON_DIR)) {
        throw "Missing embedded Python folder: $PYTHON_DIR"
    }

    Test-RustToolchain
    Test-PythonEnv $pythonBin
    Test-NodeModules

    Push-Location $APP_DIR
    npm run tauri build -- --no-bundle
    Pop-Location

    $targetDir = Join-Path $APP_DIR "src-tauri\target\release"
    Write-Host "Windows build complete."
    Write-Host "Output: $targetDir\pdf2excel.exe"
    Write-Host "Resources are embedded in the exe. No additional files needed."
}

if ($Target -eq "-h" -or $Target -eq "--help") {
    Show-Usage
    exit 0
}

if ($Target -eq "windows") {
    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        Build-Windows
    } else {
        throw "Windows build must run on Windows."
    }
}