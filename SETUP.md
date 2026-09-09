# Setup Instructions

## Phase 0: Environment Initiation (Prerequisites)

Before you can run this infrastructure, your Windows machine must be configured to run Docker containers natively.

1. **Windows Subsystem for Linux (WSL2)**
   Docker Desktop on Windows relies on WSL2 for high performance container execution.
   - Open PowerShell as Administrator and run: `wsl --install`
   - Restart your computer if prompted.

2. **Install Docker Desktop**
   - Download and install [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/).
   - During installation, ensure the **"Use WSL 2 instead of Hyper-V"** option is checked.
   - Once installed, open the Docker Desktop application and leave it running in the background.

3. **Verify Dependencies**
   *(Note: Docker Compose v2 and PowerShell are already built into modern Windows/Docker Desktop installations).*
   
   Open a standard PowerShell window and verify Docker is running:
   ```powershell
   docker --version
   docker compose version
   ```

## Initial Setup

> [!IMPORTANT]
> **Execution Context:**
> - If you **cloned the repository**, use the PowerShell script: `.\stack.ps1 <command>`
> - If you **downloaded the release .zip**, use the compiled binary: `.\stack <command>`
> 
> *The documentation examples below use `.\stack` as shorthand.*

1. **Automated Setup:**
   Run the built-in setup wizard to automatically initialize your environment. This will copy all `.env.example` templates, create required host directories, and configure your global network.

   **Choose Your Storage Architecture:**
   - **Option A (Default - Bind Mounts):** Stores all container data directly in physical folders on your C: drive (`../data/`). Ideal for easy backups, direct file access, and local editing.
     ```powershell
     .\stack setup
     ```
   
   - **Option B (Docker Volumes):** Stores all container data inside Docker's internal, managed Named Volumes. Ideal if you experience file permission or file-sharing issues on Docker Desktop for Windows.
     ```powershell
     .\stack setup -UseVolumes
     ```

   > [!IMPORTANT]
   > Ensure you open the newly generated `.env` files inside the `config/` directory and update the default credentials before starting your services!

2. **Verify Configuration:**
   ```powershell
   .\stack config
   ```
   Ensure no syntax errors are reported.

3. **Start Services:**
   Start the default core group:
   ```powershell
   .\stack up
   ```

4. **Verify Running Containers:**
   ```powershell
   .\stack status
   .\stack health
   ```

5. **Access:**
   Your services should now be accessible on `http://<service>.localhost`.

## Troubleshooting

> [!WARNING]
> **Docker Desktop File Sharing Issues**
> If you are using the default Bind Mounts (Option A) and encounter errors where containers complain about "Permission Denied" or missing files (like a database migration failure), Docker Desktop might be struggling to sync files between Windows and WSL2. 
> 
> **Fix:** Completely tear down the stack (`.\stack down`), run `.\stack setup -UseVolumes` to switch your global architecture to Docker Named Volumes, and bring it back up.
