#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$ROOT_DIR/pdf2excel"
RESOURCES_DIR="$APP_DIR/src-tauri/resources"
PYTHON_DIR="$RESOURCES_DIR/python"
REQUIREMENTS_FILE="$RESOURCES_DIR/requirements.txt"

die() {
  echo "Error: $*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

OS="$(uname -s)"
ARCH="$(uname -m)"

if [[ "$OS" == "Darwin" ]]; then
  case "$ARCH" in
    arm64) PLATFORM="aarch64-apple-darwin" ;;
    x86_64) PLATFORM="x86_64-apple-darwin" ;;
    *) die "Unsupported macOS arch: $ARCH" ;;
  esac
elif [[ "$OS" == "Linux" ]]; then
  case "$ARCH" in
    x86_64) PLATFORM="x86_64-unknown-linux-gnu" ;;
    aarch64) PLATFORM="aarch64-unknown-linux-gnu" ;;
    *) die "Unsupported Linux arch: $ARCH" ;;
  esac
else
  die "Unsupported OS: $OS. Use prepare-embedded-python.ps1 on Windows."
fi

need_cmd curl
need_cmd tar

PYTHON_VERSION="${PYTHON_VERSION:-3.11.9}"
PYTHON_BS_TAG="${PYTHON_BS_TAG:-20240224}"
ASSET="cpython-${PYTHON_VERSION}+${PYTHON_BS_TAG}-${PLATFORM}-install_only.tar.gz"
PYTHON_URL="${PYTHON_URL:-https://github.com/indygreg/python-build-standalone/releases/download/${PYTHON_BS_TAG}/${ASSET}}"

echo "Preparing embedded Python in: $PYTHON_DIR"
echo "Using: $PYTHON_URL"

TMP_DIR="$(mktemp -d)"
ARCHIVE="$TMP_DIR/$ASSET"
EXTRACT_DIR="$TMP_DIR/extract"
mkdir -p "$EXTRACT_DIR"

curl -L "$PYTHON_URL" -o "$ARCHIVE" || die "Download failed. Set PYTHON_URL to a valid asset."
tar -xf "$ARCHIVE" -C "$EXTRACT_DIR"

PYTHON_BIN="$(find "$EXTRACT_DIR" -type f -path "*/bin/python3" | head -n1 || true)"
[[ -n "$PYTHON_BIN" ]] || die "python3 not found in extracted archive."

PYTHON_ROOT="$(cd "$(dirname "$PYTHON_BIN")/.." && pwd)"
rm -rf "$PYTHON_DIR"
mkdir -p "$PYTHON_DIR"
cp -R "$PYTHON_ROOT"/. "$PYTHON_DIR"/

"$PYTHON_DIR/bin/python3" -m ensurepip --upgrade
"$PYTHON_DIR/bin/python3" -m pip install --upgrade pip
"$PYTHON_DIR/bin/python3" -m pip install -r "$REQUIREMENTS_FILE"
"$PYTHON_DIR/bin/python3" -c "import pdfplumber, openpyxl, pdfminer, PIL"

echo "Embedded Python ready."
