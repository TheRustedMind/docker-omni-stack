# Networking

## Shared Docker Network
All modular services connect to the `project-network`. This shared bridge network enables Docker DNS, allowing containers to communicate using their service names.

### Service-to-Service Communication
Internal communication should **always** use the Docker DNS names defined in the `compose/*.yml` files.

**Correct:**
```text
http://cliproxyapi:8317
http://postgres:5432
http://redis:6379
http://qdrant:6333
```

**Incorrect:**
```text
http://localhost:8317
http://127.0.0.1:5432
```
`localhost` inside a container resolves to that container itself, not the host machine or other containers.

## Port Exposure
Only expose ports that must be accessed from the host machine or outside network.
- **Exposed by default:** Web interfaces (n8n, Uptime Kuma, Open WebUI).
- **Not exposed by default:** Databases (postgres, redis) and internal APIs unless specifically configured in `.env`.

## Caddy Reverse Proxy
If you want to proxy services or add HTTPS locally, use the Caddy service. Caddy can route requests by container name over the `project-network`.
Do not publicly expose sensitive services unless Authentik or another secure authentication layer is placed in front.
