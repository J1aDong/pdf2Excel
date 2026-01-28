$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AppDir = Join-Path $RootDir "pdf2excel"
$ResourcesDir = Join-Path $AppDir "src-tauri/resources"
$PythonDir = Join-Path $ResourcesDir "python"
$RequirementsFile = Join-Path $ResourcesDir "requirements.txt"

function Die($Message) {
  Write-Error $Message
  exit 1
}

if (-not (Get-Command tar -ErrorAction SilentlyContinue)) {
  Die "Missing required command: tar"
}

$PythonVersion = if ($env:PYTHON_VERSION) { $env:PYTHON_VERSION } else { "3.11.9" }
$PythonTag = if ($env:PYTHON_BS_TAG) { $env:PYTHON_BS_TAG } else { "20240224" }
$Asset = "cpython-$PythonVersion+$PythonTag-x86_64-pc-windows-msvc-shared-install_only.tar.gz"
$PythonUrl = if ($env:PYTHON_URL) { $env:PYTHON_URL } else { "https://github.com/indygreg/python-build-standalone/releases/download/$PythonTag/$Asset" }

Write-Host "Preparing embedded Python in: $PythonDir"
Write-Host "Using: $PythonUrl"

$TmpDir = Join-Path $env:TEMP "pdf2excel-python"
if (Test-Path $TmpDir) {
  Remove-Item $TmpDir -Recurse -Force
}
New-Item -ItemType Directory -Path $TmpDir | Out-Null

$Archive = Join-Path $TmpDir $Asset
Invoke-WebRequest -Uri $PythonUrl -OutFile $Archive
tar -xf $Archive -C $TmpDir

$PythonBin = Get-ChildItem -Path $TmpDir -Recurse -Filter python.exe | Select-Object -First 1
if (-not $PythonBin) {
  Die "python.exe not found in extracted archive."
}

$SrcRoot = Split-Path $PythonBin.FullName -Parent
if (Test-Path $PythonDir) {
  Remove-Item $PythonDir -Recurse -Force
}
New-Item -ItemType Directory -Path $PythonDir | Out-Null
Copy-Item -Path (Join-Path $SrcRoot "*") -Destination $PythonDir -Recurse -Force

$Python = Join-Path $PythonDir "python.exe"
& $Python -m ensurepip --upgrade
& $Python -m pip install --upgrade pip
& $Python -m pip install -r $RequirementsFile
& $Python -c "import pdfplumber, openpyxl, pdfminer, PIL"

Write-Host "Embedded Python ready."
