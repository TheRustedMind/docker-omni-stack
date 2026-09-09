# Use Cases & Deployment Blueprints

Because this infrastructure is highly modular, you don't need to run all 22 services at once. You can mix and match services to build exactly what you need. 

> [!IMPORTANT]
> **Execution Context:**
> - Cloned Repo (Development): Use `.\stack.ps1 <command>`
> - Release .zip (End-Users): Use `.\stack <command>`
> 
> *The examples below use `.\stack` as shorthand.*

Here are three concrete examples of ecosystems you can instantly deploy.

---

## 1. Local AI & Private ChatGPT Clone

**Goal:** Build a completely private, offline LLM inference ecosystem with a beautiful web UI and Retrieval-Augmented Generation (RAG) capabilities.

**Required Services:**
- `ollama` (Local LLM Inference Engine)
- `litellm` (API Proxy for routing/logging)
- `open-webui` (Beautiful ChatGPT-style interface)
- `qdrant` (Vector Database for RAG and document search)

**How to deploy it:**
Because the script handles dependency mapping, you simply need to bring up `open-webui` and `qdrant`. The binary will automatically pull in `ollama` (needed by open-webui).

```powershell
.\stack up open-webui qdrant
```

**Result:** You will have a fully functional AI chat interface running on `http://open-webui.localhost`, completely offline.

---

## 2. Advanced Data Processing & Automation Pipeline

**Goal:** Build a robust workflow automation system capable of scraping emails, extracting text from PDFs, processing the data with AI, and storing the results in a database.

**Required Services:**
- `n8n` (Workflow Automation Engine)
- `tika` (Document text extraction)
- `postgres` (Relational Database)
- `cliproxyapi` (Custom proxy for specific APIs)

**How to deploy it:**
```powershell
.\stack up n8n tika cliproxyapi postgres
```

**Result:** `n8n` acts as the orchestrator. You can build visual workflows in n8n that fetch PDFs, send them to the internal `http://tika:9998` endpoint to extract text, and then save the structured text directly into the `postgres` database. 

---

## 3. Self-Hosted Dev, API & Monitoring Ecosystem

**Goal:** Run a lightweight local development suite for testing APIs, hosting Git repositories, and monitoring uptime.

**Required Services:**
- `gitea` (Lightweight Git hosting)
- `hoppscotch` (API testing client, similar to Postman)
- `uptime-kuma` (Ping and status monitoring)

**How to deploy it:**
```powershell
.\stack up gitea hoppscotch uptime-kuma
```

**Result:** 
- Push your code to your local `gitea` instance.
- Test your webhooks and local APIs using `hoppscotch`.
- Configure `uptime-kuma` to monitor all your internal endpoints via their Caddy domains (e.g., configuring it to ping `http://hoppscotch.localhost`).

---

## 4. Secure Database Management with Zero-Trust Identity

**Goal:** Run a Web UI for PostgreSQL (pgAdmin) that is securely hidden behind a Caddy reverse proxy and protected by Authentik identity verification (ForwardAuth).

**Required Services:**
- `postgres` (Relational Database)
- `pgadmin` (Database Web UI)
- `caddy` (Reverse Proxy)
- `authentik` (Identity Provider & ForwardAuth)

**How to deploy it:**
```powershell
.\stack up pgadmin caddy authentik
```
*(Dependencies like `postgres` and `redis` will start automatically).*

**How to configure the Zero-Trust Proxy:**
By default, the `Caddyfile` is configured to route `pgadmin.localhost` through Authentik. However, Authentik requires a brief one-time setup to authorize the proxy:
1. Go to `http://authentik.localhost/if/flow/initial-setup/` and follow the prompts to create your default `akadmin` password.
2. Go to **Admin Interface** > **Applications** > **Providers** > Create a **Proxy Provider**.
   - Name: `pgadmin-proxy`
   - Authorization flow: `default-provider-authorization-explicit-consent`
   - Type: `Forward auth (single application)`
   - External host: `https://pgadmin.localhost`
3. Go to **Applications** > Create an **Application**.
   - Name: `pgAdmin`
   - Slug: `pgadmin`
   - Provider: `pgadmin-proxy`
4. Go to **Outposts** > Edit the **authentik Embedded Outpost** and add the `pgAdmin` application to it.

**Result:** 
When you visit `http://pgadmin.localhost` in your browser, Caddy will intercept the request, redirect you to the Authentik login portal, and only allow you to access the pgAdmin database UI after you have successfully verified your identity!

---

> [!TIP]
> **Don't forget to tear down!**
> When you are finished experimenting with a specific use case, you can instantly cleanly tear down the entire stack and free up your computer's RAM without losing any data:
> ```powershell
> .\stack down
> ```
