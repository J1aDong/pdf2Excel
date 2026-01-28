# PDF 转 Excel

一个基于 **Tauri + Python** 的桌面应用，用于将采购订单 PDF 文件智能转换为可编辑的 Excel 表格。

## 架构设计

### Tauri + Python (嵌入式) 架构

```
Vue 前端 ↔ Tauri (Rust) ↔ 嵌入式 Python ↔ pdfplumber/openpyxl
```

**优势：**
- ✅ Python 的 PDF 解析库（pdfplumber）成熟可靠
- ✅ 无需 OCR，直接提取 PDF 文本层
- ✅ 体积控制：仅增加 Python 运行时（~10-15MB）
- ✅ 跨平台：Windows/macOS 均支持

### 为何不用纯 Rust？

| 方案 | 体积 | 解析准确度 | 维护成本 |
|------|------|-----------|----------|
| 纯 Rust (lopdf) | ~5MB | 中（PDF 结构复杂） | 高 |
| **Tauri + Python** | ~15MB | **高（pdfplumber 成熟）** | **低** |
| Tauri + OCR | ~50MB+ | 高 | 中 |

## 原始需求

### 核心功能
- **输入**: 采购订单 PDF 文件
- **输出**: Excel 文件，格式匹配：
  - 日期、客户名、订单号
  - 零件号、零件描述/规格
  - 数量、价格（未税）、金额（未税）
  - 计划交货日期、订单交期

### 技术栈
- **框架**: Tauri v2（Rust 后端 + Web 前端）
- **PDF 处理**: Python + pdfplumber
- **Excel 导出**: Python + openpyxl
- **前端**: Vue 3 + TypeScript + Tailwind CSS
- **目标平台**: Windows + macOS

### OCR 需求分析
**结论：不需要 OCR**

PDF 内部已包含可提取的文本层，直接使用 pdfplumber 提取数据即可。

### 界面设计
- **简洁导入**: 拖拽或点击导入 PDF
- **实时预览**: 表格渲染在页面中
- **在线编辑**: 直接修改单元格、增删行
- **一键导出**: 导出为 .xlsx 文件

## 项目结构

```
pdf2excel/
├── src/                          # Vue 前端
│   ├── components/               # UI 组件
│   ├── stores/                   # Pinia 状态管理
│   ├── App.vue                   # 主界面
│   └── main.ts                   # 入口
├── src-tauri/
│   ├── src/lib.rs                # Rust 后端（调用 Python）
│   ├── Cargo.toml                # Rust 依赖（精简）
│   ├── resources/                # Python 资源
│   │   ├── pdf_processor.py      # PDF 处理脚本
│   │   └── requirements.txt      # Python 依赖
│   └── ...
└── package.json
```

## 开发环境

### 前置要求
- Node.js 18+
- Rust 1.70+
- Python 3.10+（开发时使用系统 Python）

### 安装前端依赖
```bash
cd pdf2excel
npm install
```

### 安装 Python 依赖（开发）
```bash
pip3 install pdfplumber openpyxl
# 或
pip3 install -r src-tauri/resources/requirements.txt
```

### 开发模式
```bash
npm run tauri:dev
```

### 构建生产版本

#### macOS
```bash
npm run tauri:build
# 输出：src-tauri/target/release/bundle/macos/PDF转Excel.app
```

#### Windows
```bash
npm run tauri:build
# 输出：src-tauri/target/release/bundle/msi/*.msi
```

## 嵌入式 Python 配置（打包使用）

打包时使用内置 Python 运行时，**宿主不需要单独安装 Python**。

### 一键准备（推荐）
macOS/Linux：
```bash
chmod +x prepare-embedded-python.sh
./prepare-embedded-python.sh
```

Windows（PowerShell）：
```powershell
.\prepare-embedded-python.ps1
```

脚本会下载可迁移 Python，并安装依赖到：
```
src-tauri/resources/python/
```

### Git LFS 提交提示（强烈推荐）
嵌入式 Python 体积较大，建议用 Git LFS 管理：
```bash
git lfs install
git lfs track "pdf2excel/src-tauri/resources/python/**"
git add .gitattributes
git add pdf2excel/src-tauri/resources/python
git commit -m "Add embedded python (LFS)"
```

CI 默认会拉取 LFS，并在缺失时自动运行 `prepare-embedded-python.*`。

## 核心实现

### Rust → Python 通信

Rust 通过 `std::process::Command` 调用 Python 脚本，通过 STDIN/STDOUT 传递 JSON 数据：

```rust
// Rust 侧
let output = Command::new("python")
    .arg("pdf_processor.py")
    .stdin(Stdio::piped())
    .stdout(Stdio::piped())
    .spawn()?;

// 发送 JSON 请求
stdin.write_all(json!({"command": "parse", "path": "..."}))?;

// 接收 JSON 响应
let result: Value = serde_json::from_str(&stdout)?;
```

```python
# Python 侧
import sys, json

request = json.load(sys.stdin)
if request["command"] == "parse":
    result = parse_pdf(request["path"])
    print(json.dumps(result))
```

### PDF 解析逻辑

使用 pdfplumber 提取表格：

```python
with pdfplumber.open(path) as pdf:
    for page in pdf.pages:
        tables = page.extract_tables()
        for table in tables:
            # 识别表头
            # 提取数据行
            # 解析零件号、数量、价格等字段
```

### Excel 导出

使用 openpyxl 生成格式化的 Excel：

```python
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Border

ws = wb.active
# 表头样式（蓝色背景、白色字体）
# 数据边框
# 列宽设置
# 冻结首行
```

## 数据格式

### 输入 PDF 示例
```
张家港华捷电子有限公司
采购订单 PurchaseOrder
订单号： P202603563
供应商： S120030

行号 零件号 零件描述/规格 数量 单位 价格（未税） 金额（未税） 计划交货日期
1 03.002.0000042 线束(UL3266/14AWG/黑色+77/见图纸/B-线束) 6500.00 pcs 0.360000 2,340.000000 20260624
```

### 输出 Excel
| 日期 | 客户名 | 订单号 | 零件号 | 零件描述/规格 | 数量 | 价格（未税） | 金额（未税） | 计划交货日期 | 订单交期 |
|------|--------|--------|--------|--------------|------|-------------|-------------|-------------|----------|
| 2026-01-28 | 张家港华捷电子有限公司 | P202603563 | 03.002.0000042 | 线束(UL3266/14AWG/黑色+77/见图纸/B-线束) | 6500.00 | 0.36 | 2340.00 | 2026-06-24 | 2026-06-24 |

## 依赖清理

### Rust 依赖（精简后）
```toml
[dependencies]
tauri = { version = "2", features = [] }
tauri-plugin-opener = "2"
tauri-plugin-dialog = "2"
serde = { version = "1", features = ["derive"] }
serde_json = "1"
chrono = "0.4"
```

**已移除：**
- `lopdf` - 不再需要，Python 处理 PDF
- `rust_xlsxwriter` - 不再需要，Python 处理 Excel
- `regex` - 不再需要

### Python 依赖
```
pdfplumber==0.11.4      # PDF 解析
openpyxl==3.1.5         # Excel 导出
Pillow==11.0.0          # 图像处理（pdfplumber 依赖）
pdfminer.six==20240727  # PDF 文本提取
```

## 常见问题

### 1. Python 未找到
**错误**: `Failed to start Python`

**解决**: 
- macOS: `brew install python3`
- Windows: 安装 Python 并添加到 PATH

### 2. PDF 解析失败
**错误**: `未能从PDF中提取到有效的表格数据`

**解决**:
- 确保 PDF 是文本型（非扫描件）
- 检查 PDF 是否加密

### 3. 权限错误
**错误**: `Command plugin:dialog|open not allowed`

**解决**: 检查 `src-tauri/capabilities/default.json`:
```json
{
  "permissions": [
    "core:default",
    "dialog:default",
    "dialog:allow-open",
    "dialog:allow-save"
  ]
}
```

## 构建产物大小

| 平台 | 大小 | 说明 |
|------|------|------|
| macOS .app | ~15MB | 依赖系统 Python |
| Windows .exe | ~25MB | 包含嵌入式 Python |
| Windows .msi | ~20MB | 安装包 |

## 许可证

MIT License
