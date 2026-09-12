use std::fs;
use std::process::Command;
use crate::config::get_project_root;

fn build_command(base_args: Vec<&str>) -> (String, Vec<String>) {
    let exe_path = format!("{}/stack.exe", get_project_root());
    if std::path::Path::new(&exe_path).exists() {
        (exe_path, base_args.iter().map(|s| s.to_string()).collect())
    } else {
        let mut args = vec!["-File".to_string(), "stack.ps1".to_string()];
        args.extend(base_args.iter().map(|s| s.to_string()));
        ("powershell".to_string(), args)
    }
}

#[tauri::command]
pub fn execute_setup(use_volumes: bool) -> Result<String, String> {
    let global_env_path = format!("{}/config\\global.env", get_project_root());
    if let Ok(content) = fs::read_to_string(&global_env_path) {
        if content.contains("USE_DOCKER_VOLUMES=") {
            let replacer = if use_volumes { "USE_DOCKER_VOLUMES=true" } else { "USE_DOCKER_VOLUMES=false" };
            let new_content = content.lines().map(|line| {
                if line.starts_with("USE_DOCKER_VOLUMES=") {
                    replacer
                } else {
                    line
                }
            }).collect::<Vec<_>>().join("\r\n");
            let _ = fs::write(&global_env_path, new_content);
        }
    }
    
    let mut base_args = vec!["setup"];
    if use_volumes {
        base_args.push("-UseVolumes");
    }
    let (cmd, args) = build_command(base_args);
    
    let output = Command::new(cmd)
        .current_dir(get_project_root())
        .args(&args)
        .output()
        .map_err(|e| e.to_string())?;
        
    if output.status.success() {
        Ok(String::from_utf8_lossy(&output.stdout).to_string())
    } else {
        Err(String::from_utf8_lossy(&output.stderr).to_string())
    }
}

#[tauri::command]
pub fn execute_up(services: Vec<String>) -> Result<String, String> {
    let mut base_args = vec!["up"];
    let services_strs: Vec<&str> = services.iter().map(|s| s.as_str()).collect();
    base_args.extend(services_strs);
    let (cmd, args) = build_command(base_args);
    
    let output = Command::new(cmd)
        .current_dir(get_project_root())
        .args(&args)
        .output()
        .map_err(|e| e.to_string())?;
        
    if output.status.success() {
        Ok(String::from_utf8_lossy(&output.stdout).to_string())
    } else {
        Err(String::from_utf8_lossy(&output.stderr).to_string())
    }
}

#[tauri::command]
pub fn trust_certificate() -> Result<String, String> {
    let _ = Command::new("docker")
        .current_dir(get_project_root())
        .args(["cp", "caddy:/data/caddy/pki/authorities/local/root.crt", "caddy-root.crt"])
        .output();
        
    let _output = Command::new("powershell")
        .current_dir(get_project_root())
        .args(["-Command", "Start-Process powershell -ArgumentList '-Command \"Import-Certificate -FilePath caddy-root.crt -CertStoreLocation Cert:\\LocalMachine\\Root\"' -Verb RunAs -Wait"])
        .output()
        .map_err(|e| e.to_string())?;
        
    Ok("Certificate Trusted".to_string())
}

#[tauri::command]
pub fn execute_restart(services: Vec<String>) -> Result<String, String> {
    let mut base_args = vec!["restart"];
    let services_strs: Vec<&str> = services.iter().map(|s| s.as_str()).collect();
    base_args.extend(services_strs);
    let (cmd, args) = build_command(base_args);
    
    let output = Command::new(cmd)
        .current_dir(get_project_root())
        .args(&args)
        .output()
        .map_err(|e| e.to_string())?;
        
    if output.status.success() {
        Ok(String::from_utf8_lossy(&output.stdout).to_string())
    } else {
        Err(String::from_utf8_lossy(&output.stderr).to_string())
    }
}

#[tauri::command]
pub fn execute_stop(service: String) -> Result<String, String> {
    let (cmd, args) = build_command(vec!["stop", &service]);
    let output = Command::new(cmd)
        .current_dir(get_project_root())
        .args(&args)
        .output()
        .map_err(|e| e.to_string())?;
        
    if output.status.success() {
        Ok(String::from_utf8_lossy(&output.stdout).to_string())
    } else {
        Err(String::from_utf8_lossy(&output.stderr).to_string())
    }
}

#[tauri::command]
pub fn execute_down() -> Result<String, String> {
    let (cmd, args) = build_command(vec!["down"]);
    let output = Command::new(cmd)
        .current_dir(get_project_root())
        .args(&args)
        .output()
        .map_err(|e| e.to_string())?;
        
    if output.status.success() {
        Ok(String::from_utf8_lossy(&output.stdout).to_string())
    } else {
        Err(String::from_utf8_lossy(&output.stderr).to_string())
    }
}
