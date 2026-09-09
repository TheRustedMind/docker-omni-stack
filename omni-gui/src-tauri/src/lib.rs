pub mod config;
pub mod docker;
pub mod stack;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![
            config::get_registry,
            config::get_env_file,
            config::save_env_file,
            docker::get_container_status,
            docker::get_service_volumes,
            docker::list_volume_files,
            docker::upload_to_volume,
            docker::check_docker_status,
            docker::start_docker_engine,
            stack::execute_setup,
            stack::execute_up,
            stack::execute_restart,
            stack::execute_stop,
            stack::execute_down,
            stack::trust_certificate
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
