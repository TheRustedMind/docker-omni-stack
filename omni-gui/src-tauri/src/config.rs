use std::fs;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct RegistryService {
    #[serde(rename = "ComposeFile")]
    pub compose_file: String,
    #[serde(rename = "EnvFile")]
    pub env_file: String,
    #[serde(rename = "DependsOn")]
    pub depends_on: Vec<String>,
    #[serde(rename = "Group")]
    pub group: String,
    #[serde(rename = "InternalPort", skip_serializing_if = "Option::is_none")]
    pub internal_port: Option<u16>,
}

pub fn get_project_root() -> String {
    if let Ok(root) = std::env::var("OMNI_PROJECT_ROOT") {
        return root;
    }
    let mut current = std::env::current_dir().unwrap();
    if current.ends_with("src-tauri") {
        current.pop();
        current.pop();
    } else if current.ends_with("omni-gui") {
        current.pop();
    }
    current.to_str().unwrap().to_string().replace("\\", "/")
}

#[tauri::command]
pub fn get_registry() -> Result<std::collections::HashMap<String, RegistryService>, String> {
    let registry_path = format!("{}/registry.json", get_project_root());
    let content = fs::read_to_string(registry_path).map_err(|e| e.to_string())?;
    serde_json::from_str(&content).map_err(|e| e.to_string())
}

#[tauri::command]
pub fn get_env_file(service: String) -> Result<String, String> {
    let env_path = format!("{}/config/{}.env", get_project_root(), service);
    fs::read_to_string(&env_path).or_else(|_| Ok("".to_string()))
}

#[tauri::command]
pub fn save_env_file(service: String, content: String) -> Result<(), String> {
    let env_path = format!("{}/config/{}.env", get_project_root(), service);
    let dir_path = format!("{}/config", get_project_root());
    if !std::path::Path::new(&dir_path).exists() {
        fs::create_dir_all(dir_path).map_err(|e| e.to_string())?;
    }
    fs::write(&env_path, content).map_err(|e| e.to_string())
}
