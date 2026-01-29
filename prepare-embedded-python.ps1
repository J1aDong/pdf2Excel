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

# Use Python.org embedded distribution
$PythonVersion = if ($env:PYTHON_VERSION) { $env:PYTHON_VERSION } else { "3.12.8" }
$Asset = "python-$PythonVersion-embed-amd64.zip"
$PythonUrl = if ($env:PYTHON_URL) { $env:PYTHON_URL } else { "https://www.python.org/ftp/python/$PythonVersion/$Asset" }

Write-Host "Preparing embedded Python in: $PythonDir"
Write-Host "Using: $PythonUrl"

$TmpDir = Join-Path $env:TEMP "pdf2excel-python"
if (Test-Path $TmpDir) {
  Remove-Item $TmpDir -Recurse -Force
}
New-Item -ItemType Directory -Path $TmpDir | Out-Null

$Archive = Join-Path $TmpDir $Asset
Invoke-WebRequest -Uri $PythonUrl -OutFile $Archive
Expand-Archive -Path $Archive -DestinationPath $TmpDir

# For Python embed, files are extracted directly to TmpDir
$PythonBin = Join-Path $TmpDir "python.exe"
if (-not (Test-Path $PythonBin)) {
  Die "python.exe not found in extracted archive."
}

$SrcRoot = $TmpDir
if (Test-Path $PythonDir) {
  Remove-Item $PythonDir -Recurse -Force
}
New-Item -ItemType Directory -Path $PythonDir | Out-Null
Copy-Item -Path (Join-Path $SrcRoot "*") -Destination $PythonDir -Recurse -Force

$Python = Join-Path $PythonDir "python.exe"

# For embedded Python, we need to modify python3xx._pth to enable site-packages
$PthFile = Get-ChildItem -Path $PythonDir -Filter "*._pth" | Select-Object -First 1
if ($PthFile) {
  $PthContent = Get-Content $PthFile.FullName
  $NewPthContent = $PthContent -replace "^import site$", "#import site"
  $NewPthContent += "`r`nimport site"
  Set-Content -Path $PthFile.FullName -Value $NewPthContent
}

# Download get-pip.py
$GetPip = Join-Path $TmpDir "get-pip.py"
Invoke-WebRequest -Uri "https://bootstrap.pypa.io/get-pip.py" -OutFile $GetPip
& $Python $GetPip

& $Python -m pip install --upgrade pip
& $Python -m pip install -r $RequirementsFile
& $Python -c "import pdfplumber, openpyxl, pdfminer, PIL"

Write-Host "Embedded Python ready."
