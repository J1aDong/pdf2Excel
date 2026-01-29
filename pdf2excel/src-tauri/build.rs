fn main() {
    tauri_build::build();

    // 在开发环境打印资源嵌入路径信息
    #[cfg(debug_assertions)]
    {
        println!("cargo:rerun-if-changed=resources");
    }
}
