# Backup Strategies

Currently, this infrastructure relies on Docker volume mounts mapped to the `data/` folder. Backups should primarily target this directory.

## What Needs Backup?
- `data/postgres/`: Contains all database structures for LiteLLM, Flowise, Dify, Authentik, Gitea.
- `data/n8n/`: Contains n8n workflows and SQLite database (if not using Postgres).
- `data/qdrant/`: Contains vector embeddings.
- `data/minio/`: Contains uploaded objects, documents, and media.
- `data/grafana/`: Contains custom dashboards.
- `data/gitea/`: Contains git repositories.
- `config/*.env`: Your secret configuration files (backup securely!).

## Backup Process
A formal `stack.ps1 backup` command is planned for the future. For now, to backup manually:

1. Bring down the services to ensure consistency (especially databases).
   ```powershell
   .\stack.ps1 down
   ```
2. Copy or archive the `data/` directory and `config/` directory.
3. Bring services back up.
   ```powershell
   .\stack.ps1 up
   ```

Do not store backups inside this git repository unless they are added to the `.gitignore`.
