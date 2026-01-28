use serde::{Deserialize, Serialize};
use std::process::{Command, Stdio};
use std::io::{Write, Read};
use std::path::PathBuf;

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
fn get_python_path() -> PathBuf {
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
    
    if cfg!(target_os = "windows") {
        PathBuf::from("python")
    } else {
        PathBuf::from("python3")
    }
}

fn get_processor_path() -> PathBuf {
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
    
    let input_str = input_json.to_string();
    if let Some(mut stdin) = child.stdin.take() {
        stdin.write_all(input_str.as_bytes())
            .map_err(|e| format!("Failed to write to Python stdin: {}", e))?;
    }
    
    let mut stdout = String::new();
    let mut stderr = String::new();
    
    if let Some(mut pipe) = child.stdout.take() {
        pipe.read_to_string(&mut stdout)
            .map_err(|e| format!("Failed to read Python stdout: {}", e))?;
    }
    
    if let Some(mut pipe) = child.stderr.take() {
        pipe.read_to_string(&mut stderr)
            .map_err(|e| format!("Failed to read Python stderr: {}", e))?;
    }
    
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
#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
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
