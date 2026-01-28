#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$ROOT_DIR/pdf2excel"
RESOURCES_DIR="$APP_DIR/src-tauri/resources"
PYTHON_DIR="$RESOURCES_DIR/python"

usage() {
  cat <<'EOF'
Usage: ./build.sh [mac|windows|all]

Builds the Tauri app and verifies the embedded Python runtime + deps exist.
Defaults to "all" (build host OS, skip the other with a message).

Env:
  SKIP_NPM_INSTALL=1   Skip npm install if node_modules is missing.
EOF
}

die() {
  echo "Error: $*" >&2
  exit 1
}

host_os() {
  local uname_out
  uname_out="$(uname -s)"
  case "${uname_out}" in
    Darwin*) echo "mac" ;;
    MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
    Linux*) echo "linux" ;;
    *) echo "unknown" ;;
  esac
}

ensure_node_modules() {
  if [[ ! -d "$APP_DIR/node_modules" ]]; then
    if [[ "${SKIP_NPM_INSTALL:-}" == "1" ]]; then
      die "node_modules is missing. Run npm install first."
    fi
    echo "node_modules missing, running npm install..."
    (cd "$APP_DIR" && npm install)
  fi
}

check_python_env() {
  local python_bin="$1"
  if [[ ! -f "$python_bin" ]]; then
    die "Embedded Python not found at: $python_bin"
  fi
  "$python_bin" -c "import pdfplumber, openpyxl, pdfminer, PIL" >/dev/null
}

build_mac() {
  local python_bin="$PYTHON_DIR/bin/python3"
  [[ -d "$PYTHON_DIR" ]] || die "Missing embedded Python folder: $PYTHON_DIR"
  check_python_env "$python_bin"
  ensure_node_modules
  (cd "$APP_DIR" && npm run tauri:build)
  echo "macOS build complete."
}

build_windows() {
  local python_bin="$PYTHON_DIR/python.exe"
  [[ -d "$PYTHON_DIR" ]] || die "Missing embedded Python folder: $PYTHON_DIR"
  check_python_env "$python_bin"
  ensure_node_modules
  (cd "$APP_DIR" && npm run tauri:build)
  echo "Windows build complete."
}

target="${1:-all}"
case "$target" in
  -h|--help) usage; exit 0 ;;
esac

host="$(host_os)"
case "$target" in
  mac)
    [[ "$host" == "mac" ]] || die "mac build must run on macOS."
    build_mac
    ;;
  windows)
    [[ "$host" == "windows" ]] || die "Windows build must run on Windows."
    build_windows
    ;;
  all)
    if [[ "$host" == "mac" ]]; then
      build_mac
      echo "Windows build skipped (run on Windows)."
    elif [[ "$host" == "windows" ]]; then
      build_windows
      echo "macOS build skipped (run on macOS)."
    else
      die "Unsupported host OS: $host"
    fi
    ;;
  *)
    usage
    die "Unknown target: $target"
    ;;
esac
