# Project-Local Modular Docker Infrastructure

[![License: Fair Code](https://img.shields.io/badge/License-Fair_Code-blue.svg)](https://faircode.io/)

**Core Platform**  
[![Docker](https://img.shields.io/badge/Docker-2CA5E0?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)
[![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=flat&logo=github-actions&logoColor=white)](https://github.com/features/actions)
[![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=flat&logo=powershell&logoColor=white)](https://microsoft.com/PowerShell)

**Data & Storage**  
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=flat&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Redis](https://img.shields.io/badge/redis-%23DD0031.svg?style=flat&logo=redis&logoColor=white)](https://redis.io/)
[![MinIO](https://img.shields.io/badge/MinIO-%23C7202C.svg?style=flat&logo=minio&logoColor=white)](https://min.io/)
[![Qdrant](https://img.shields.io/badge/Qdrant-EC4899?style=flat)](https://qdrant.tech/)

**AI Ecosystem**  
[![Ollama](https://img.shields.io/badge/Ollama-white?style=flat&logo=ollama&logoColor=black)](https://ollama.com/)
[![LiteLLM](https://img.shields.io/badge/LiteLLM-4285F4?style=flat)](https://litellm.ai/)
[![Open WebUI](https://img.shields.io/badge/Open_WebUI-3498DB?style=flat)](https://openwebui.com/)
[![Flowise](https://img.shields.io/badge/Flowise-27AE60?style=flat)](https://flowiseai.com/)
[![Dify](https://img.shields.io/badge/Dify-1890FF?style=flat)](https://dify.ai/)

**Workflow & Processing**  
[![n8n](https://img.shields.io/badge/n8n-%23EA4B71.svg?style=flat&logo=n8n&logoColor=white)](https://n8n.io/)
[![RabbitMQ](https://img.shields.io/badge/RabbitMQ-%23FF6600.svg?style=flat&logo=rabbitmq&logoColor=white)](https://www.rabbitmq.com/)
[![Apache Tika](https://img.shields.io/badge/Apache_Tika-D22128?style=flat&logo=apache&logoColor=white)](https://tika.apache.org/)
[![Gotenberg](https://img.shields.io/badge/Gotenberg-000000?style=flat)](https://gotenberg.dev/)

**Networking & Security**  
[![Caddy](https://img.shields.io/badge/Caddy-%23000000.svg?style=flat&logo=caddy&logoColor=white)](https://caddyserver.com/)
[![Authentik](https://img.shields.io/badge/Authentik-FD4B2D?style=flat&logo=goauthentik&logoColor=white)](https://goauthentik.io/)

**Monitoring & Developer Tools**  
[![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=flat&logo=prometheus&logoColor=white)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/grafana-%23F46800.svg?style=flat&logo=grafana&logoColor=white)](https://grafana.com/)
[![Uptime Kuma](https://img.shields.io/badge/Uptime_Kuma-58A6FF?style=flat)](https://uptime.kuma.pet/)
[![Gitea](https://img.shields.io/badge/Gitea-34495E?style=flat&logo=gitea&logoColor=5D9425)](https://gitea.io/)
[![Hoppscotch](https://img.shields.io/badge/Hoppscotch-31C48D?style=flat&logo=hoppscotch&logoColor=white)](https://hoppscotch.io/)
## Project Purpose
This repository provides a highly modular, general-purpose Docker infrastructure framework managed natively via PowerShell. Instead of forcing a monolithic stack, it allows you to dynamically mix-and-match over 20+ pre-configured microservices to build exactly the environment you need—whether that's a private AI ecosystem, a data processing pipeline, a web hosting stack, or an API development suite.

This repository's orchestration code and configuration files are licensed under a **Fair-Code / Business Source** model, integrated with **Apache 2.0** patent protections. 

- **Free for Individuals & Small Businesses:** You are granted full freedom to use, modify, and run this infrastructure for personal, educational, or internal small-business use.
- **Enterprise & SaaS Commercial Use:** If you intend to offer this infrastructure as a managed commercial SaaS product to third parties, or if you exceed a certain revenue threshold, a commercial license is required. 
- **Patent Protection (Apache-style):** All authorized users are granted explicit patent protections and immunity from patent litigation regarding this codebase.

> **Third-Party Licensing Disclaimer:** The license above applies *exclusively* to the orchestration code (PowerShell scripts and YAML configurations) within this repository. The individual services and Docker images orchestrated by this framework (e.g., n8n, Redis, Qdrant) are subject to their respective creators' open-source and fair-code licenses.

This infrastructure comes pre-configured with 22 production-ready services, logically grouped into modular ecosystems:

- **Automation & Integration**: `n8n`, `cliproxyapi`
- **AI Ecosystem**: `ollama`, `litellm`, `open-webui`, `flowise`, `dify`, `qdrant` (Vector DB)
- **Data & Databases**: `postgres`, `pgadmin`, `redis`, `minio` (S3 Storage)
- **Monitoring & Observability**: `prometheus`, `grafana`, `uptime-kuma`
- **Networking & Security**: `caddy` (Reverse Proxy), `authentik` (SSO/Auth)
- **Tools & Processing**: `hoppscotch` (API testing), `gitea` (Git hosting), `rabbitmq` (Message queue), `tika`, `gotenberg`

## Prerequisites
- Windows 10 or Windows 11
- Docker Desktop
- Docker Compose v2
- PowerShell

## Quick Start & Commands

> [!IMPORTANT]
> **Execution Context:**
> - If you **cloned the repository** (for development), use the PowerShell script: `.\stack.ps1 <command>`
> - If you **downloaded the release .zip**, use the compiled binary: `.\stack <command>`
> 
> *The documentation examples below use `.\stack` as shorthand. Please substitute it with `.\stack.ps1` if you are working from the repository source.*

### First-Time Installation
```powershell
.\stack setup
# Or, to use managed Docker Volumes instead of local folders:
.\stack setup -UseVolumes
```

### Start Services

You can start any combination of services by passing their names. The framework automatically resolves and boots their required databases (e.g. Postgres/Redis) for you!

```powershell
# Example: Start the AI chat stack
.\stack up open-webui qdrant

# Example: Start the automation pipeline
.\stack up n8n tika
```

Start specific groups:
```powershell
.\stack up -Group data
.\stack up -Group ai
.\stack up -Group ai-apps
.\stack up -Group monitoring
```

Start specific services (automatically starts dependencies):
```powershell
.\stack up n8n
.\stack up authentik
```

### Manage Services
```powershell
.\stack down        # Stop services (preserves data)
.\stack restart     # Restart core services
.\stack logs        # View logs
.\stack pull        # Pull updates
.\stack update      # Update and restart
```

### Inspection
```powershell
.\stack services    # List all registered services and their groups/dependencies
.\stack groups      # List all registered groups
.\stack status      # Show container status
.\stack health      # Show health status
.\stack config      # Validate compose config
.\stack help        # Show help
```

## Adding Services
Configuration files are stored in `config/`.
Compose files are stored in `compose/`.
Data is mounted in `data/`.
You can add a new service by creating its `.yml` and `.env` files, then adding it to `$Registry` inside `scripts/Registry.ps1`.

## Documentation
- [INFRASTRUCTURE.md](INFRASTRUCTURE.md) - Deep dive into architecture, service discovery, and native volume switching.
- [SETUP.md](SETUP.md) - Detailed first-time installation, configuration, and volume toggle guide.
- [SERVICES.md](SERVICES.md) - Comprehensive list of all supported services and their dependency trees.
- [USE_CASES.md](USE_CASES.md) - Concrete examples and deployment blueprints (e.g., Local AI, Data Automation).
### Advanced Documentation
The `docs/` folder contains advanced operational guides:
- [docs/authentication.md](docs/authentication.md) - SSO, reverse proxy, and access control.
- [docs/networking.md](docs/networking.md) - Network topologies and Caddy proxy routing.
- [docs/security.md](docs/security.md) - Environment security and best practices.
- [docs/backup.md](docs/backup.md) - Data persistence and backup strategies.
- [docs/troubleshooting.md](docs/troubleshooting.md) - Solutions to common infrastructure errors.

## Service Status & Automated Testing

This repository includes an automated testing framework to ensure all services are healthy and functional. The table below is automatically updated by `.\stack test`.

<!-- TEST_RESULTS_START -->
| Service | Status | Last Tested | Has Custom Test |
|---------|--------|-------------|-----------------|
| **authentik** | Unknown | Never | No |
| **caddy** | Pass | 2026-09-04 21.18.17 | No |
| **cliproxyapi** | Pass | 2026-09-04 21.18.17 | No |
| **dify** | Unknown | Never | No |
| **flowise** | Unknown | Never | No |
| **gitea** | Unknown | Never | No |
| **gotenberg** | Unknown | Never | No |
| **grafana** | Unknown | Never | No |
| **hoppscotch** | Unknown | Never | No |
| **litellm** | Unknown | Never | No |
| **minio** | Unknown | Never | No |
| **n8n** | Unknown | Never | No |
| **ollama** | Unknown | Never | No |
| **open-webui** | Unknown | Never | No |
| **pgadmin** | Unknown | Never | No |
| **postgres** | Unknown | Never | No |
| **prometheus** | Unknown | Never | No |
| **qdrant** | Unknown | Never | No |
| **rabbitmq** | Unknown | Never | No |
| **redis** | Unknown | Never | No |
| **tika** | Unknown | Never | No |
| **uptime-kuma** | Unknown | Never | No |
<!-- TEST_RESULTS_END -->

---

## Credits & Acknowledgments

This framework stands entirely on the shoulders of giants. All credit for the incredible software encapsulated within this infrastructure goes to their respective open-source maintainers, creators, and communities:

- **[n8n](https://n8n.io/)** - Fair-code workflow automation.
- **[Ollama](https://ollama.com/)** - Get up and running with large language models locally.
- **[PostgreSQL](https://www.postgresql.org/)** & **[Redis](https://redis.io/)** - The legendary data foundations of the modern web.
- **[Open WebUI](https://openwebui.com/)** - Extensible, feature-rich UI for local LLMs.
- **[Caddy](https://caddyserver.com/)** - The ultimate enterprise-ready open source web server with automatic HTTPS.
- **[Authentik](https://goauthentik.io/)** - Versatile open-source identity provider.
- **[Qdrant](https://qdrant.tech/)** - High-performance, massive-scale Vector Database.
- **[Hoppscotch](https://hoppscotch.io/)** - Open source API development ecosystem.
- **[MinIO](https://min.io/)**, **[Grafana](https://grafana.com/)**, **[Prometheus](https://prometheus.io/)**, **[Gitea](https://gitea.io/)**, **[Uptime Kuma](https://uptime.kuma.pet/)**, and all other incredible tools included in this stack!
