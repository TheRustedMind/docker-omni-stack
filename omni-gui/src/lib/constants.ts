export const SERVICE_DESCRIPTIONS: Record<string, string> = {
  caddy: "Dynamic reverse proxy and SSL provider.",
  authentik: "Zero-Trust SSO and Identity Provider.",
  postgres: "Primary relational database for stack services.",
  redis: "In-memory caching and message broker.",
  n8n: "Workflow automation and orchestration.",
  flowise: "No-code LLM app builder.",
  dify: "LLM application development platform.",
  "open-webui": "User-friendly AI interface.",
  ollama: "Local LLM model runner.",
  litellm: "LLM proxy and load balancer.",
  qdrant: "Vector database for AI embeddings.",
  pgadmin: "PostgreSQL administration interface.",
  minio: "S3-compatible object storage.",
  "uptime-kuma": "Uptime monitoring and alerting.",
  prometheus: "Metrics collection and aggregation.",
  grafana: "Metrics visualization dashboard.",
  gitea: "Self-hosted Git service.",
  tika: "Document parsing and extraction.",
  gotenberg: "PDF generation API.",
  hoppscotch: "API development and testing workspace.",
  rabbitmq: "Message broker.",
  cliproxyapi: "CLI automation bridge."
};

export const DB_PORTS: Record<string, number> = {
  postgres: 5432,
  redis: 6379,
  rabbitmq: 5672
};
