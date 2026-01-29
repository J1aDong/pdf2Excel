use serde::{Deserialize, Serialize};
use std::process::{Command, Stdio};
use std::io::{Write, Read};
use std::path::PathBuf;
use rust_embed::RustEmbed;

// === Embedded Resources ===
#[derive(RustEmbed)]
#[folder = "resources/"]
struct Resources;

// === Types ===
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct OrderItem {
    pub id: String,
    pub 日期: String,
    pub 客户名: String,
    pub 订单号: String,
    pub 零件号: String,
    pub 零件描述: String,
    pub 数量: String,
    pub 价格: String,
    pub 金额: String,
    pub 计划交货日期: String,
    pub 订单交期: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct PdfInfo {
    #[serde(rename = "orderNo", alias = "order_no")]
    pub order_no: String,
    #[serde(rename = "supplierNo", alias = "supplier_no")]
    pub supplier_no: String,
    #[serde(rename = "supplierName", alias = "supplier_name")]
    pub supplier_name: String,
    #[serde(rename = "customerName", alias = "customer_name")]
    pub customer_name: String,
    pub currency: String,
}

#[derive(Debug, Serialize)]
pub struct ParseResult {
    pub items: Vec<OrderItem>,
    pub info: PdfInfo,
}

// === Python Integration ===

// 提取嵌入资源到临时目录
fn extract_resource_to_temp(relative_path: &str) -> Result<PathBuf, String> {
    let temp_dir = std::env::temp_dir();
    let app_temp_dir = temp_dir.join("pdf2excel");

    // 创建应用临时目录
    if !app_temp_dir.exists() {
        std::fs::create_dir_all(&app_temp_dir)
            .map_err(|e| format!("Failed to create temp dir: {}", e))?;
    }

    let target_path = app_temp_dir.join(relative_path);

    // 如果文件已存在，直接返回
    if target_path.exists() {
        return Ok(target_path);
    }

    // 从嵌入资源中获取文件
    let resource_path = relative_path.replace("\\", "/");
    match Resources::get(&resource_path) {
        Some(embedded_file) => {
            // 通过路径判断是否是目录（以 / 结尾或已存在目录标记）
            let is_dir = relative_path.ends_with('/') || resource_path.ends_with('/');

            if is_dir {
                std::fs::create_dir_all(&target_path)
                    .map_err(|e| format!("Failed to create directory: {}", e))?;
            } else {
                // 确保父目录存在
                if let Some(parent) = target_path.parent() {
                    if !parent.exists() {
                        std::fs::create_dir_all(parent)
                            .map_err(|e| format!("Failed to create parent directory: {}", e))?;
                    }
                }
                // 写入文件
                std::fs::write(&target_path, embedded_file.data)
                    .map_err(|e| format!("Failed to write file: {}", e))?;
            }
            Ok(target_path)
        }
        None => Err(format!("Resource not found: {}", resource_path)),
    }
}

// 递归提取整个目录
fn extract_dir_to_temp(relative_path: &str) -> Result<(), String> {
    let resource_path = if relative_path.ends_with('/') {
        relative_path.to_string()
    } else {
        format!("{}/", relative_path)
    };

    // 提取所有匹配的资源
    for file in Resources::iter() {
        let file_str = file.as_ref();
        if file_str.starts_with(&resource_path) {
            extract_resource_to_temp(file_str)?;
        }
    }

    Ok(())
}

fn get_python_path() -> PathBuf {
    // 首先尝试从临时目录查找（嵌入资源已提取）
    let temp_dir = std::env::temp_dir().join("pdf2excel");
    if cfg!(target_os = "windows") {
        let temp_path = temp_dir.join("python/python.exe");
        if temp_path.exists() {
            return temp_path;
        }
    }

    // 尝试从 exe 目录查找
    let exe_dir = std::env::current_exe()
        .unwrap_or_default()
        .parent()
        .map(|p| p.to_path_buf())
        .unwrap_or_default();

    if cfg!(target_os = "windows") {
        let paths = [
            exe_dir.join("python").join("python.exe"),
            exe_dir.join("python.exe"),
        ];
        for path in &paths {
            if path.exists() {
                return path.clone();
            }
        }
    } else {
        let paths = [
            exe_dir.join("../Resources/python/bin/python3"),
            exe_dir.join("python/bin/python3"),
            exe_dir.join("python3"),
        ];
        for path in &paths {
            if path.exists() {
                return path.canonicalize().unwrap_or_else(|_| path.clone());
            }
        }
    }

    // 尝试从嵌入资源提取
    if cfg!(target_os = "windows") {
        if let Ok(path) = extract_resource_to_temp("python/python.exe") {
            return path;
        }
    }

    if cfg!(target_os = "windows") {
        PathBuf::from("python")
    } else {
        PathBuf::from("python3")
    }
}

fn get_processor_path() -> PathBuf {
    // 首先尝试从临时目录查找（嵌入资源已提取）
    let temp_dir = std::env::temp_dir().join("pdf2excel");
    let temp_path = temp_dir.join("pdf_processor.py");
    if temp_path.exists() {
        return temp_path;
    }

    // 尝试从 exe 目录查找
    let exe_dir = std::env::current_exe()
        .unwrap_or_default()
        .parent()
        .map(|p| p.to_path_buf())
        .unwrap_or_default();

    let paths = [
        exe_dir.join("../Resources/pdf_processor.py"),
        exe_dir.join("pdf_processor.py"),
        exe_dir.join("resources/pdf_processor.py"),
    ];

    for path in &paths {
        if path.exists() {
            return path.canonicalize().unwrap_or_else(|_| path.clone());
        }
    }

    // 尝试从嵌入资源提取
    if let Ok(path) = extract_resource_to_temp("pdf_processor.py") {
        return path;
    }

    PathBuf::from("src-tauri/resources/pdf_processor.py")
}

fn call_python(input_json: serde_json::Value) -> Result<serde_json::Value, String> {
    let python_path = get_python_path();
    let script_path = get_processor_path();

    if !script_path.exists() {
        return Err(format!("Python script not found: {:?}", script_path));
    }

    let mut cmd = Command::new(&python_path);
    cmd.arg(&script_path)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped());

    let mut child = cmd.spawn()
        .map_err(|e| format!("Failed to start Python: {} (path: {:?})", e, python_path))?;

    // 使用 serde_json::to_vec 来确保正确编码 UTF-8，不转义 Unicode
    let input_bytes = serde_json::to_vec(&input_json)
        .map_err(|e| format!("Failed to serialize JSON: {}", e))?;
    if let Some(mut stdin) = child.stdin.take() {
        stdin.write_all(&input_bytes)
            .map_err(|e| format!("Failed to write to Python stdin: {}", e))?;
    }
    
    let mut stdout = String::new();
    let mut stderr_bytes = Vec::new();

    if let Some(mut pipe) = child.stdout.take() {
        pipe.read_to_string(&mut stdout)
            .map_err(|e| format!("Failed to read Python stdout: {}", e))?;
    }

    if let Some(mut pipe) = child.stderr.take() {
        pipe.read_to_end(&mut stderr_bytes)
            .map_err(|e| format!("Failed to read Python stderr: {}", e))?;
    }

    // 尝试将 stderr 转换为 UTF-8 字符串，如果失败则使用占位符
    let stderr = String::from_utf8_lossy(&stderr_bytes).to_string();
    
    let status = child.wait()
        .map_err(|e| format!("Failed to wait for Python: {}", e))?;
    
    if !status.success() {
        return Err(format!("Python process failed: {} (stderr: {})", status.code().unwrap_or(-1), stderr));
    }
    
    let output: serde_json::Value = serde_json::from_str(&stdout)
        .map_err(|e| format!("Failed to parse Python output: {} (output: {})", e, stdout))?;
    
    if let Some(error) = output.get("error") {
        return Err(error.as_str().unwrap_or("Unknown error").to_string());
    }
    
    Ok(output)
}

// === Tauri Commands ===
#[tauri::command]
fn test_command() -> String {
    "Hello from Rust!".to_string()
}

#[tauri::command]
fn parse_pdf(path: String) -> Result<ParseResult, String> {
    let input = serde_json::json!({
        "command": "parse",
        "path": path
    });
    
    let result = call_python(input)?;
    
    let items: Vec<OrderItem> = result.get("items")
        .and_then(|v| serde_json::from_value(v.clone()).ok())
        .unwrap_or_default();
    
    let info: PdfInfo = result.get("info")
        .and_then(|v| serde_json::from_value(v.clone()).ok())
        .unwrap_or(PdfInfo {
            order_no: String::new(),
            supplier_no: String::new(),
            supplier_name: String::new(),
            customer_name: String::new(),
            currency: "CNY".to_string(),
        });
    
    if items.is_empty() {
        return Err("未能从PDF中提取到有效的表格数据".to_string());
    }
    
    Ok(ParseResult { items, info })
}

#[tauri::command]
fn export_excel(path: String, data: Vec<OrderItem>, _info: PdfInfo) -> Result<(), String> {
    let input = serde_json::json!({
        "command": "export",
        "path": path,
        "data": data,
        "info": _info
    });
    
    call_python(input)?;
    Ok(())
}

#[tauri::command]
fn check_python() -> Result<bool, String> {
    let python_path = get_python_path();
    let script_path = get_processor_path();
    Ok(python_path.exists() && script_path.exists())
}

// === App Entry ===

// 初始化嵌入资源
fn init_embedded_resources() {
    // 提取 pdf_processor.py
    let _ = extract_resource_to_temp("pdf_processor.py");

    // 提取完整的 Python 目录（包括所有子目录和文件）
    let _ = extract_dir_to_temp("python/");
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    // 初始化嵌入资源
    init_embedded_resources();
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_dialog::init())
        .invoke_handler(tauri::generate_handler![
            test_command,
            parse_pdf,
            export_excel,
            check_python
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
