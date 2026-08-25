# Authentication JSON Schemas

Several services in the modular Docker stack rely on JSON files mapped via volumes for authentication tokens and credentials.

## 1. CLIProxyAPI Credentials (`credentials.json`)
Location: `data/cliproxyapi/auth/credentials.json`

### Schema Overview
This file contains the OAuth2/access token schema required for the CLIProxyAPI to authenticate requests (e.g. against Google APIs or custom services).

```json
{
    "access_token": "string (the actual Bearer token)",
    "disabled": "boolean (false)",
    "email": "string (e.g., user@example.com)",
    "expired": "string (ISO 8601 Timestamp, e.g., '2026-08-25T13:12:54+08:00')",
    "expires_in": "integer (seconds, e.g., 3599)",
    "project_id": "string (the GCP or custom project ID)",
    "refresh_token": "string (the token used to get a new access token)",
    "timestamp": "integer (Unix epoch timestamp in milliseconds)",
    "type": "string (e.g., 'antigravity')"
}
```

### Steps to Create / Generate this JSON
1. **Obtain Tokens**: You must manually authenticate with your provider (like Google Cloud Platform) using their CLI tools (e.g., `gcloud auth login`) or a custom OAuth2 consent flow.
2. **Extract the Tokens**: Once authenticated, extract the `access_token` and `refresh_token`. 
3. **Construct the JSON**:
   - Create a file at `data/cliproxyapi/auth/credentials.json`.
   - Paste the extracted tokens into the JSON structure shown above.
   - Set the `timestamp` to the current Unix epoch time in milliseconds.
   - Set the `expired` string to 1 hour from the current time.
4. **Restart Service**: Restart the CLIProxyAPI to pick up the new tokens:
   ```powershell
   .\stack.ps1 restart cliproxyapi
   ```
   *Note: If the `refresh_token` is valid, the proxy should automatically refresh the `access_token` when it expires.*

## 2. Other Services
Currently, no other services rely on raw `.json` files for primary authentication (they use environment variables stored in `.env`). If additional services (like custom n8n nodes) require JSON credentials, document them here following the format above.
