# Networking

## Shared Docker Network
All modular services connect to their designated group subnets (e.g., `core-network`, `data-network`). These isolated bridge networks provide Zero-Trust segregation, allowing containers within the same group to communicate securely.

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
- **Exposed by default:** None. All Web interfaces are mediated exclusively by the Caddy reverse proxy on ports 80/443.
- **Not exposed by default:** Databases (postgres, redis) and internal APIs unless specifically configured in `.env`.

## Caddy Reverse Proxy
If you want to proxy services or add HTTPS locally, use the Caddy service. Caddy dynamically attaches to all active group networks in the stack, bridging them together securely.
Do not publicly expose sensitive services unless Authentik or another secure authentication layer is placed in front.
