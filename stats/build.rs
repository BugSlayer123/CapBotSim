use std::env;
use std::fs;
use std::path::Path;

fn main() {
    let binary_name = env::var("CARGO_PKG_NAME").expect("CARGO_PKG_NAME not set");

    let target_dir = env::var("CARGO_TARGET_DIR")
        .map_or_else(|_| "target".to_string(), |t| t);

    let release_binary = Path::new(&target_dir).join("release").join(&binary_name);
    let destination = Path::new("..").join(&binary_name);

    if release_binary.exists() {
        fs::copy(&release_binary, &destination)
            .expect("Failed to copy binary");
        println!("Copied {} to {:?}", binary_name, destination);
    } else {
        eprintln!("Error: Release binary not found at {:?}", release_binary);
    }
}
