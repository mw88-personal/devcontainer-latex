# LaTeX Devcontainer

A VS Code devcontainer for LaTeX development with TeX Live 2025, chktex, latexindent, Oh My Posh, and poppler-utils.

<!-- BEGIN FEATURES -->
## Features
- **TeX Live 2025**: Full LaTeX environment with LuaHBTeX for modern typesetting.
- **chktex**: Linting with customizable configurations (`chktex-config.rc`, `chktex-config-default.rc`).
- **latexindent**: Code formatting with settings in `latexindent-config.yaml`.
- **Oh My Posh**: Custom shell prompt via `ohmyposh-theme.json`.
- **poppler-utils**: Tools for PDF manipulation, including `pdfseparate` for splitting PDFs.
- **Git Integration**: Passes through host Git configuration (via environment variables or inherited settings).
- **SSH Support**: Relies on host SSH agent (Windows/WSL2) for secure repository access.
- **User/Permissions**: Runs as user `dev` (UID/GID 1001) for consistent permissions in WSL2.
- **WSL2 Compatibility**: Optimized for Docker Desktop on WSL2 with LF line endings.
<!-- END FEATURES -->

<!-- BEGIN PREREQUISITES -->
## Prerequisites
- **Docker Desktop**: Required for running the devcontainer.
- **VS Code**: Install with the **Dev Containers** extension (`ms-vscode-remote.remote-containers`).
- **WSL2**: Recommended for Linux compatibility on Windows.
- **SSH Agent**: Required for SSH access, running on the host (Windows/WSL2).
<!-- END PREREQUISITES -->

<!-- BEGIN BUILD -->
## Build Instructions
1. Build the Docker image locally:
   ```bash
   cd /path/to/devcontainer
   docker build -f src/Dockerfile -t noctuidus/devcontainer-latex:{{TAG}} --build-arg TAG={{TAG}} .
   ```
2. Create releases via GitHub Actions:
   - Trigger on tag push (e.g., `git tag v0.9.5; git push --tags`).
   - Outputs:
     - `latex-devcontainer-core-{{TAG}}.zip`: Prebuilt image.
     - `latex-devcontainer-source-{{TAG}}.zip`: Local build, no demo.
     - `latex-devcontainer-example-{{TAG}}.zip`: Prebuilt image with demo.
<!-- END BUILD -->

<!-- BEGIN USAGE -->
## Usage
1. Download a release from GitHub:
   - Core: `latex-devcontainer-core-{{TAG}}.zip` (prebuilt image).
   - Source: `latex-devcontainer-source-{{TAG}}.zip` (local build).
   - Example: `latex-devcontainer-example-{{TAG}}.zip` (prebuilt image with demo).
2. Extract to your project:
   ```bash
   cd /path/to/your/project
   unzip ~/Downloads/latex-devcontainer-core-{{TAG}}.zip
   mv latex-devcontainer-core-{{TAG}}/.devcontainer .
   # For example release:
   unzip ~/Downloads/latex-devcontainer-example-{{TAG}}.zip
   mv latex-devcontainer-example-{{TAG}}/.devcontainer .
   mv latex-devcontainer-example-{{TAG}}/example .
   # Copy other dependencies as needed
   ```
3. Open in VS Code:
   ```bash
   code .
   # Reopen in Container
   ```
4. Compile LaTeX files using `Ctrl+Alt+B` in VS Code or:
   ```bash
   latexmk
   # configuration is read from latexmkrc
   ```
5. Split a PDF (using poppler-utils):
   ```bash
   pdfseparate build/main.pdf build/page-%d.pdf
   ```
<!-- END USAGE -->

<!-- BEGIN CONFIG -->
## Configuration Overrides
- Place per-project configuration files in your project directory below `.config/` to override defaults:
  - `.config/chktex-config.rc`: Overrides `~/.chktexrc`.
  - `.config/latexindent-config.yaml`: Overrides default latexindent config.
  - `.config/ohmyposh-theme.json`: Overrides default ohmyposh theme.
- Example:
  ```bash
  echo "VerbTeX {custom}" > .config/chktex-config.rc
  chktex -l .config/chktex-config.rc main.tex
  ```
<!-- END CONFIG -->

<!-- BEGIN EXAMPLE -->
## Example Usage
1. Ensure `.devcontainer/` and `example/` are in your project root (from `latex-devcontainer-example-{{TAG}}.zip`).
2. Compile the demo:
   ```bash
   cd example
   latexmk
   ```
3. View output in `build/example.pdf`.
<!-- END EXAMPLE -->

<!-- BEGIN DEBUG -->
## Debugging
- **SSH Agent**: Ensure the SSH agent is running on the host (Windows/WSL2):
  ```bash
  # On WSL2
  eval $(ssh-agent)
  ssh-add ~/.ssh/id_rsa
  # Verify
  ssh -T git@github.com
  ```
- **Git Configuration**: Verify Git configuration is passed through from the host:
  ```bash
  git config --global --list
  # Set if needed
  git config --global user.name "Your Name"
  git config --global user.email "your.email@example.com"
  ```
- **User/Permissions**: Check UID/GID in container:
  ```bash
  id dev
  # Should output: uid=1001(dev) gid=1001(dev)
  ```
- **Line Endings**: Ensure LF endings:
  ```bash
  git config --global core.autocrlf false
  file main.tex # Should show LF
  ```
<!-- END DEBUG -->