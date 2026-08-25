# Use Cases & Deployment Blueprints

Because this infrastructure is highly modular, you don't need to run all 21 services at once. You can mix and match services to build exactly what you need. 

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
Because the script handles dependency mapping, you simply need to bring up `open-webui` and `qdrant`. The binary will automatically pull in `ollama`, `litellm`, and `postgres` (needed by litellm).

```powershell
.\stack up open-webui qdrant
```

**Result:** You will have a fully functional AI chat interface running on `localhost:3000` (or whichever port you specified in `.env`), completely offline.

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
.\stack up n8n tika cliproxyapi
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
- Configure `uptime-kuma` to monitor all your internal endpoints using Docker DNS (e.g., configuring it to ping `http://hoppscotch:3000`).

---

> [!TIP]
> **Don't forget to tear down!**
> When you are finished experimenting with a specific use case, you can instantly cleanly tear down the entire stack and free up your computer's RAM without losing any data:
> ```powershell
> .\stack down
> ```
