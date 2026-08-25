# Troubleshooting

### Docker Desktop is not running
**Symptoms:** `stack.ps1` immediately errors out mentioning Docker is unavailable.
**Solution:** Start Docker Desktop from the Start Menu and wait for the engine to initialize.

### Port already in use
**Symptoms:** `Bind for 0.0.0.0:xxxx failed: port is already allocated.`
**Solution:** Another application on your PC is using the port. Change the corresponding `HOST_PORT` variable in the `config/*.env` file for the failing service, then restart it.

### Environment file missing
**Symptoms:** `stack.ps1` says `Missing environment file for...`
**Solution:** You need to copy the `.env.example` file to `.env` in the `config/` directory for the service you are trying to start.

### Service name cannot be resolved
**Symptoms:** A container (e.g., n8n) complains it cannot reach another container (e.g., postgres).
**Solution:** Ensure both containers are running. Ensure they are on the `project-network`. Ensure you are using the service name (`postgres`) and not `localhost`. Use `.\stack.ps1 status` to check if containers are healthy.

### Persistent data is missing
**Symptoms:** After restarting, a service loses all configuration.
**Solution:** Ensure you used `.\stack.ps1 down` and not `docker compose down -v` (which deletes volumes). Ensure the volume mapping in the compose file points to a valid folder in `data/`.
