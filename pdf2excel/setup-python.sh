#!/bin/bash
# 设置嵌入式 Python 环境脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOURCES_DIR="$SCRIPT_DIR/src-tauri/resources"
PYTHON_DIR="$RESOURCES_DIR/python"

echo "=== PDF2Excel Python Setup ==="
echo "Target directory: $PYTHON_DIR"

# 检测系统
OS="$(uname -s)"
ARCH="$(uname -m)"

echo "OS: $OS, Arch: $ARCH"

# 创建目录
mkdir -p "$PYTHON_DIR"

if [[ "$OS" == "Darwin" ]]; then
    # macOS
    if [[ "$ARCH" == "arm64" ]]; then
        # Apple Silicon
        PYTHON_URL="https://www.python.org/ftp/python/3.12.1/python-3.12.1-macos11.pkg"
        echo "Downloading Python for macOS ARM64..."
        # 对于 macOS，我们使用系统 Python 或 Homebrew Python
        # 嵌入式 Python 在 macOS 上比较复杂，这里提供说明
        echo "Note: On macOS, the app will use system Python3."
        echo "Please ensure python3 is installed: brew install python"
    else
        # Intel
        echo "Intel Mac detected. Using system Python3."
    fi
    
    # 安装 Python 依赖到用户目录
    echo "Installing Python dependencies..."
    pip3 install --user -r "$RESOURCES_DIR/requirements.txt" || {
        echo "Trying with python3 -m pip..."
        python3 -m pip install --user -r "$RESOURCES_DIR/requirements.txt"
    }
    
elif [[ "$OS" == "Linux" ]]; then
    # Linux
    echo "Linux detected. Please install Python3 and pip."
    echo "Then run: pip3 install -r $RESOURCES_DIR/requirements.txt"
    
else
    # Windows (通过 Git Bash 或 WSL)
    echo "Windows detected."
    echo "Please download Windows embeddable package from:"
    echo "https://www.python.org/downloads/windows/"
    echo "Extract to: $PYTHON_DIR"
    echo "Then install requirements.txt"
fi

echo ""
echo "Setup complete!"
echo "To verify, run: python3 $RESOURCES_DIR/pdf_processor.py"
