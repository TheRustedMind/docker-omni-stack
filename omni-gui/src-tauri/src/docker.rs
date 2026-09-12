use std::fs;
use std::process::Command;
use serde::{Serialize};
use crate::config::get_project_root;

#[derive(Serialize)]
pub struct VolumeInfo {
    mount_type: String, // "volume" or "bind"
    name_or_source: String,
    destination: String,
}

#[tauri::command]
pub fn get_container_status(service: String) -> Result<String, String> {
    let output = Command::new("docker")
        .args(["ps", "--filter", &format!("label=com.docker.compose.service={}", service), "--format", "{{.Status}}"])
        .output()
        .map_err(|e| e.to_string())?;
    
    let status = String::from_utf8_lossy(&output.stdout).trim().to_string();
    if status.is_empty() {
        Ok("Stopped".to_string())
    } else {
        Ok(status)
    }
}

pub fn get_fallback_volumes(service: &str) -> Vec<VolumeInfo> {
    let global_env_path = format!("{}/config\\global.env", get_project_root());
    let mut use_docker_volumes = true;
    if let Ok(content) = fs::read_to_string(&global_env_path) {
        if content.contains("USE_DOCKER_VOLUMES=false") {
            use_docker_volumes = false;
        }
    }
    
    let mut volumes = Vec::new();
    
    if use_docker_volumes {
        let root = get_project_root();
        let project_name = std::path::Path::new(&root).file_name().unwrap().to_str().unwrap().to_lowercase().chars().filter(|c| c.is_ascii_alphanumeric()).collect::<String>();
        let prefix = format!("{}_", project_name);

        if service == "authentik" {
            volumes.push(VolumeInfo { mount_type: "volume".to_string(), name_or_source: format!("{}authentik_media", prefix), destination: "/media".to_string() });
            volumes.push(VolumeInfo { mount_type: "volume".to_string(), name_or_source: format!("{}authentik_certs", prefix), destination: "/certs".to_string() });
            volumes.push(VolumeInfo { mount_type: "volume".to_string(), name_or_source: format!("{}authentik_templates", prefix), destination: "/templates".to_string() });
        } else if service == "caddy" {
            volumes.push(VolumeInfo { mount_type: "volume".to_string(), name_or_source: format!("{}caddy_data", prefix), destination: "/data".to_string() });
            volumes.push(VolumeInfo { mount_type: "volume".to_string(), name_or_source: format!("{}caddy_config", prefix), destination: "/config".to_string() });
        } else {
            let vol_key = service.replace("-", ""); 
            let vol_name = format!("{}{}_data", prefix, vol_key);
            let dest = match service {
                "n8n" => "/home/node/.n8n",
                "postgres" => "/var/lib/postgresql/data",
                _ => "/data"
            };
            volumes.push(VolumeInfo { mount_type: "volume".to_string(), name_or_source: vol_name, destination: dest.to_string() });
        }
    } else {
        let base_dir = format!("{}/data", get_project_root());
        if service == "authentik" {
            volumes.push(VolumeInfo { mount_type: "bind".to_string(), name_or_source: format!("{}\\authentik\\media", base_dir), destination: "/media".to_string() });
            volumes.push(VolumeInfo { mount_type: "bind".to_string(), name_or_source: format!("{}\\authentik\\certs", base_dir), destination: "/certs".to_string() });
            volumes.push(VolumeInfo { mount_type: "bind".to_string(), name_or_source: format!("{}\\authentik\\custom-templates", base_dir), destination: "/templates".to_string() });
        } else if service == "caddy" {
            volumes.push(VolumeInfo { mount_type: "bind".to_string(), name_or_source: format!("{}\\caddy\\data", base_dir), destination: "/data".to_string() });
            volumes.push(VolumeInfo { mount_type: "bind".to_string(), name_or_source: format!("{}\\caddy\\config", base_dir), destination: "/config".to_string() });
        } else {
            let dest = match service {
                "n8n" => "/home/node/.n8n",
                "postgres" => "/var/lib/postgresql/data",
                _ => "/data"
            };
            volumes.push(VolumeInfo { mount_type: "bind".to_string(), name_or_source: format!("{}\\{}", base_dir, service), destination: dest.to_string() });
        }
    }
    volumes
}

#[tauri::command]
pub fn get_service_volumes(service: String) -> Result<Vec<VolumeInfo>, String> {
    let output = Command::new("docker")
        .args(["ps", "-a", "--filter", &format!("label=com.docker.compose.service={}", service), "--format", "{{.Names}}"])
        .output().map_err(|e| e.to_string())?;
        
    let container_name = String::from_utf8_lossy(&output.stdout).trim().to_string();
    if container_name.is_empty() {
        return Ok(get_fallback_volumes(&service));
    }
    
    let output = Command::new("docker")
        .args(["inspect", "--format", "{{json .Mounts}}", &container_name])
        .output().map_err(|e| e.to_string())?;
        
    let json_str = String::from_utf8_lossy(&output.stdout);
    if json_str.trim().is_empty() {
        return Ok(get_fallback_volumes(&service));
    }
    
    let mounts: serde_json::Value = serde_json::from_str(&json_str).map_err(|_| "Failed to parse mounts".to_string())?;
    
    let mut volumes = Vec::new();
    if let Some(arr) = mounts.as_array() {
        for m in arr {
            let m_type = m["Type"].as_str().unwrap_or("").to_string();
            let dest = m["Destination"].as_str().unwrap_or("").to_string();
            if m_type == "volume" {
                let name = m["Name"].as_str().unwrap_or("").to_string();
                volumes.push(VolumeInfo { mount_type: m_type, name_or_source: name, destination: dest });
            } else if m_type == "bind" {
                let source = m["Source"].as_str().unwrap_or("").to_string();
                volumes.push(VolumeInfo { mount_type: m_type, name_or_source: source, destination: dest });
            }
        }
    }
    
    if volumes.is_empty() {
        return Ok(get_fallback_volumes(&service));
    }
    
    Ok(volumes)
}

#[tauri::command]
pub fn upload_to_volume(mount_type: String, name_or_source: String, local_path: String, wipe: bool) -> Result<String, String> {
    let is_archive = local_path.to_lowercase().ends_with(".zip") || local_path.to_lowercase().ends_with(".tar") || local_path.to_lowercase().ends_with(".tar.gz");
    
    if mount_type == "bind" {
        if !name_or_source.to_lowercase().starts_with(&format!("{}/data", get_project_root()).to_lowercase()) {
            return Err("Security Error: Bind mount source must be within project data directory".to_string());
        }
        let dest_dir = &name_or_source;
        
        if wipe {
            let _ = fs::remove_dir_all(dest_dir);
            let _ = fs::create_dir_all(dest_dir);
        } else {
            let _ = fs::create_dir_all(dest_dir);
        }
        
        if is_archive {
            if local_path.to_lowercase().ends_with(".zip") {
                let output = Command::new("powershell")
                    .args(["-Command", &format!("Expand-Archive -Path '{}' -DestinationPath '{}' -Force", local_path, dest_dir)])
                    .output().map_err(|e| e.to_string())?;
                if !output.status.success() { return Err(String::from_utf8_lossy(&output.stderr).to_string()); }
            } else {
                let output = Command::new("tar")
                    .args(["-xf", &local_path, "-C", dest_dir])
                    .output().map_err(|e| e.to_string())?;
                if !output.status.success() { return Err(String::from_utf8_lossy(&output.stderr).to_string()); }
            }
        } else {
            let file_name = std::path::Path::new(&local_path).file_name().unwrap().to_str().unwrap();
            let dest_file = format!("{}\\{}", dest_dir, file_name);
            fs::copy(&local_path, &dest_file).map_err(|e| e.to_string())?;
        }
        
    } else if mount_type == "volume" {
        let is_valid_vol = name_or_source.chars().all(|c| c.is_ascii_alphanumeric() || c == '-' || c == '_');
        if !is_valid_vol {
            return Err("Security Error: Invalid volume name".to_string());
        }
        let vol_name = &name_or_source;
        
        if wipe {
            let output = Command::new("docker")
                .args(["run", "--rm", "-v", &format!("{}:/vol", vol_name), "alpine", "sh", "-c", "rm -rf /vol/*"])
                .output().map_err(|e| e.to_string())?;
            if !output.status.success() { return Err(String::from_utf8_lossy(&output.stderr).to_string()); }
        }
        
        let container_name = format!("upload_dummy_{}", std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).unwrap().as_secs());
        
        let output = Command::new("docker")
            .args(["container", "create", "--name", &container_name, "-v", &format!("{}:/vol", vol_name), "alpine", "tail", "-f", "/dev/null"])
            .output().map_err(|e| e.to_string())?;
        if !output.status.success() { return Err(String::from_utf8_lossy(&output.stderr).to_string()); }
        
        let file_name = std::path::Path::new(&local_path).file_name().unwrap().to_str().unwrap();
        let dest_path = format!("{}:/{}", container_name, file_name);
        
        let output = Command::new("docker")
            .args(["cp", &local_path, &dest_path])
            .output().map_err(|e| e.to_string())?;
            
        if !output.status.success() { 
            let _ = Command::new("docker").args(["rm", "-f", &container_name]).output();
            return Err(String::from_utf8_lossy(&output.stderr).to_string()); 
        }
        
        if is_archive {
            let _ = Command::new("docker").args(["start", &container_name]).output();
            
            let extract_args = if local_path.to_lowercase().ends_with(".zip") {
                vec!["exec", container_name.as_str(), "sh", "-c", "cd /vol && unzip \"/\" && rm \"/\"", "--", file_name]
            } else {
                vec!["exec", container_name.as_str(), "sh", "-c", "cd /vol && tar -xf \"/\" && rm \"/\"", "--", file_name]
            };
            
            let output = Command::new("docker")
                .args(&extract_args)
                .output().map_err(|e| e.to_string())?;
                
            if !output.status.success() { 
                let _ = Command::new("docker").args(["rm", "-f", &container_name]).output();
                return Err(String::from_utf8_lossy(&output.stderr).to_string()); 
            }
        } else {
            let _ = Command::new("docker").args(["start", &container_name]).output();
            
            let extract_args = vec!["exec", container_name.as_str(), "sh", "-c", "mv \"/\" /vol/ || true", "--", file_name];
            
            let _ = Command::new("docker").args(&extract_args).output();
        }
        
        let _ = Command::new("docker").args(["rm", "-f", &container_name]).output();
    }
    
    Ok("Success".to_string())
}

#[tauri::command]
pub fn list_volume_files(mount_type: String, name_or_source: String) -> Result<Vec<String>, String> {
    let mut files = Vec::new();
    if mount_type == "bind" {
        if let Ok(entries) = fs::read_dir(&name_or_source) {
            for entry in entries.flatten() {
                if let Ok(name) = entry.file_name().into_string() {
                    let is_dir = entry.file_type().map(|t| t.is_dir()).unwrap_or(false);
                    files.push(if is_dir { format!("{}/", name) } else { name });
                }
            }
        }
    } else {
        let output = Command::new("docker")
            .args(["run", "--rm", "-v", &format!("{}:/vol", name_or_source), "alpine", "ls", "-1p", "/vol"])
            .output()
            .map_err(|e| e.to_string())?;
            
        if output.status.success() {
            let stdout = String::from_utf8_lossy(&output.stdout);
            for line in stdout.lines() {
                if !line.trim().is_empty() && line != "./" && line != "../" {
                    files.push(line.to_string());
                }
            }
        } else {
            return Err(String::from_utf8_lossy(&output.stderr).to_string());
        }
    }
    Ok(files)
}

#[tauri::command]
pub fn check_docker_status() -> bool {
    let output = Command::new("docker")
        .arg("info")
        .output();
    match output {
        Ok(out) => out.status.success(),
        Err(_) => false,
    }
}

#[tauri::command]
pub fn start_docker_engine() -> Result<String, String> {
    let output = Command::new("powershell")
        .args(["-Command", "Start-Process 'C:\\Program Files\\Docker\\Docker\\Docker Desktop.exe'"])
        .output()
        .map_err(|e| e.to_string())?;
        
    if output.status.success() {
        Ok("Starting".to_string())
    } else {
        Err(String::from_utf8_lossy(&output.stderr).to_string())
    }
}
