# Security

## Environment Variables
The modular infrastructure relies heavily on environment variables for configuring credentials, API keys, and secret keys.

- **`.env.example`**: These files are safe to commit. They contain dummy placeholders like `change_me` or `secure_password_here`.
- **`.env`**: These are real environment files and **MUST NOT** be committed to Git. The provided `.gitignore` automatically ignores all `*.env` files (except `.env.example`).

## Secrets
Never place API keys, passwords, or tokens directly inside `compose/*.yml` files. Always use `${VARIABLE_NAME}` and provide the value inside the respective `config/*.env` file.

## Public Internet Exposure
Do **not** expose your services publicly without careful consideration.
- If using Caddy to expose services, ensure strong passwords are used.
- For extra security, place Authentik in front of sensitive endpoints.
- Keep database ports (postgres, redis) hidden from the host unless strictly needed for debugging.
