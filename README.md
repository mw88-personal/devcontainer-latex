# LaTeX Devcontainer (TeX Live 2025)

A VS Code devcontainer for LaTeX development with TeX Live 2025, LuaHBTeX, latexmk, chktex, latexindent, and Oh My Posh.

## Features
- Non-root user (`dev`, UID/GID 1000).
- TeXlive 2025, ``scheme-full``
- preconfigured chktex
- preconfigured latexindent
- git, uses host credentials by default
- gnuplot
- prerequistites for ``minted`` package installed, i.e. python, pygmentize
- imagemagick
- bash with oh-my-posh for better shell
- Prebuilt font cache for `luaotfload`.
- Configured for LuaLaTeX compilation.
- ``openssh-client``, required for properly working with git. If used in vscode, shares host keychain.

## Getting Started
1. Clone: `git clone https://github.com/noctuidus/latex-devcontainer`
2. Open the example: `cd example && code .`
3. Run ``Dev Containers: Reopen in Container``.
4. Test:
   ```bash
   cd /ws
   latexmk
   ```
   Output: `build/example.pdf` (open with a PDF viewer).

## Configuration Files
| Repository File                    | Container Location                            | Purpose                        |
| ---------------------------------- | --------------------------------------------- | ------------------------------ |
| `config/chktex-config.rc`          | `/home/dev/.chktexrc`                         | `chktex` linter configuration  |
| `config/latexindent-config.yaml`   | `/home/dev/.indentconfig.yaml`                | `latexindent` configuration    |
| `config/latexindent-settings.yaml` | `/home/dev/.latexindent/defaultSettings.yaml` | `latexindent` default settings |
| `config/texlive-profile.tlp`       | `/tmp/texlive/tl.profile`                     | TeX Live installation profile  |
| `config/ohmyposh-theme.json`       | `/home/dev/.ohmyposh/theme.omp.json`          | Oh My Posh shell theme         |

## Reuse in Other Projects
### Option 1: Use Prebuilt Image (Recommended)
Download `latex-devcontainer-minimal.zip` from [Releases](https://github.com/noctuidus/latex-devcontainer/releases) and extract to your project's `.devcontainer/`. It contains `devcontainer.json` and `docker-compose.yml` configured for `noctuidus/devcontainer-latex:<tag>`.

### Option 2: Build Locally
Download `latex-devcontainer-full.zip` from [Releases](https://github.com/noctuidus/latex-devcontainer/releases) and extract to your project's `.devcontainer/`. Build the image:
```bash
cd .devcontainer
docker build -t latex-devcontainer .
```

## Releases
Releases are automatically generated via GitHub Actions:
- `latex-devcontainer-minimal.zip`: For prebuilt image users (`.devcontainer/` with `devcontainer.json` and `docker-compose.yml`).
- `latex-devcontainer-full.zip`: For local builds (`.devcontainer/` with `Dockerfile`, `config/`, `devcontainer.json`, and `docker-compose.yml` with commented-out `image`).

## Troubleshooting
### SSH Agent
#### Install SSH agent on windows client
~~~powershell
# Make sure you're running as an Administrator
Set-Service ssh-agent -StartupType Automatic
Start-Service ssh-agent
Get-Service ssh-agent
~~~
#### Configure SSH agent
https://superuser.com/a/1631971/390394


