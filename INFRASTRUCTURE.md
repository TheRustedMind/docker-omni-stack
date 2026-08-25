# Infrastructure Overview

This document explains the full architecture of the modular Docker setup.

## Project Root Architecture

> [!IMPORTANT]
> **Execution Context Note:** 
> When interacting with this infrastructure, developers working in the cloned repository must use `.\stack.ps1`, whereas end-users who downloaded the release must use `.\stack`. The documentation below uses `.\stack` interchangeably.

The infrastructure runs completely relative to the project root directory where the script/binary resides. 

- `compose/`: Contains all modular Docker Compose files (`.yml`).
- `config/`: Contains all environment files (`.env` and `.env.example`).
- `apps/`: Used for service-specific config files, placeholders, or static web apps.
- `data/`: Mount point for all container persistent storage.
- `docs/`: Additional architecture documentation.

## Docker Compose Modular Design

The deployment dynamically combines `compose/base.yml` (containing the shared `project-network`) with any specific service `.yml` and `.env` files via `stack`. This ensures we do not run one massive compose file, allowing lightweight partial deployments.

## Dynamic Native Volume Switching

This infrastructure features a highly advanced, zero-override storage architecture. Every service is natively configured to support both local bind mounts and internal Docker volumes without requiring duplicate compose files.

By default, Docker Compose evaluates storage paths using shell fallback variables (e.g., `${VOL_POSTGRES_DATA:-${PROJECT_DATA_DIR:-../data}/postgres}`). 
- If you use the standard setup, it routes all data transparently to the physical folders on your host machine (`../data/`).
- If you run `.\stack setup -UseVolumes`, the PowerShell wrapper intercepts the deployment and forcefully injects memory variables (`$env:VOL_POSTGRES_DATA = "postgres_data"`). Docker Compose catches these variables and dynamically pivots all storage routing into true Docker Named Volumes on the fly.

## Service Discovery & Networking

Containers communicate internally using Docker DNS on the `project-network`. 

```text
                    ┌─────────────┐
                    │    Caddy    │
                    └──────┬──────┘
                           │
          ┌────────────────┼───────────────┐
          │                │               │
          ▼                ▼               ▼
        n8n          Open WebUI       Grafana
          │                │
          ├────────────┬───┘
          │            │
          ▼            ▼
    CLIProxyAPI      LiteLLM
          │            │
          └──────┬─────┘
                 │
          ┌──────┴──────┐
          ▼             ▼
       Ollama       Cloud APIs

          ┌─────────────────────────┐
          │ PostgreSQL │ Redis      │
          │ Qdrant     │ MinIO      │
          └─────────────────────────┘
```

## Service Groups

Services are logically grouped for easier management (e.g. `core`, `data`, `ai`, `monitoring`). Using `.\stack up -Group data` will start PostgreSQL, Redis, and MinIO together.

## Service Dependencies

If a service relies on a database, `stack.exe` handles the start order. For example, `authentik` relies on `postgres` and `redis`. Running `.\stack.exe up authentik` automatically pulls in those data services.
