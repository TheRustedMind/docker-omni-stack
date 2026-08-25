# Supported Services

Below is a comprehensive list of all 21 services natively implemented in this modular infrastructure. 

> [!NOTE]
> **Automatic Dependency Resolution**
> You never have to worry about manually starting dependencies! If you run `.\stack up open-webui`, the binary will automatically crawl the dependency tree and transparently boot up `ollama` and `postgres` for you in the correct order.

## Automation & Integration Group
- **n8n**: Workflow automation.
- **cliproxyapi**: CLI proxy utility.

## Data Group
- **postgres**: Primary relational database.
- **redis**: Key-value store and cache.
- **minio**: S3-compatible object storage.

## AI Group
- **qdrant**: Vector database.
- **ollama**: Local LLM inference.
- **litellm**: OpenAI API proxy. (Depends on: `postgres`)

## AI Apps Group
- **open-webui**: UI for Ollama/LiteLLM. (Depends on: `ollama`)
- **flowise**: Visual AI workflow builder. (Depends on: `postgres`)
- **dify**: Advanced LLM App development platform. (Depends on: `postgres`, `redis`)

## Monitoring Group
- **uptime-kuma**: Status page and monitoring tool.
- **prometheus**: Metrics scraper.
- **grafana**: Metrics visualization dashboard. (Depends on: `prometheus`)

## Networking Group
- **caddy**: Reverse proxy.

## Auth Group
- **authentik**: Identity provider. (Depends on: `postgres`, `redis`)

## Development Group
- **gitea**: Git server. (Depends on: `postgres`)

## Processing Group
- **tika**: Document parsing.
- **gotenberg**: Document conversion to PDF.

## Tools Group
- **hoppscotch**: Web-based API testing client.

## Optional Group
- **rabbitmq**: Message broker queue.
