# syntax=docker/dockerfile:1.4

ARG DEBIAN_VERSION=12.11-slim
ARG TEXLIVE_VERSION=2025
ARG TEXLIVE_MIRROR=http://ctan.math.utah.edu/ctan/tex-archive/systems/texlive/tlnet
ARG CHKTEX_VERSION=1.7.9
ARG PERL_VERSION=5.38.2
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG USER_NAME=dev

# Stage 1: Build chktex in temporary container
FROM debian:${DEBIAN_VERSION}  as chktex-builder
ARG CHKTEX_VERSION
WORKDIR /tmp/chktex-builddir
RUN <<EOF
    apt-get update -y
    apt-get install -y --no-install-recommends build-essential ca-certificates make wget
    # Download and verify chktex
    wget --progress=dot:giga -O chktex.tar.gz http://download.savannah.gnu.org/releases/chktex/chktex-${CHKTEX_VERSION}.tar.gz || { echo "Failed to download chktex"; exit 1; }
    tar -xz --strip-components=1 -f chktex.tar.gz
    ./configure
    make
    mv chktex /tmp
    rm -rf *
    apt-get remove -y build-essential ca-certificates make wget
    apt-get clean autoclean
    apt-get autoremove -y
    rm -rf /var/lib/apt/lists/*
EOF


# Stage 2: Build TeX Live in temporary container
FROM perl:${PERL_VERSION} AS texlive-builder
WORKDIR /tmp/texlive
ARG TEXLIVE_VERSION
ARG TEXLIVE_MIRROR

COPY config/texlive-profile.tlp tl.profile
# Install Perl dependencies (cached layer)
# the installation of cpan modules is separated, such that rebuilding time is lower: this part does not change as often, so it does not need to be rebuilt on every build
RUN <<EOF
    echo "Installing Perl dependencies..."
    export CPANM_OPTS="--force --notest"
    for i in 1 2 3; do
        cpan -i Bundle::LWP Log::Dispatch::File YAML::Tiny File::HomeDir && break ||
        echo "CPAN attempt $i failed, retrying..." && sleep 5;
    done || { echo "Failed to install Perl dependencies"; exit 1; }
    # Verify Perl installation
    echo "Verifying Perl installation..."
    perl -v
    [ -s "/usr/local/lib/perl5/5.38.2/x86_64-linux-gnu/CORE/libperl.so" ] || { echo "libperl.so is missing or empty"; exit 1; }
    echo "Perl dependencies and libraries verified."
EOF
# Install TeX Live
# add the path, so tlmgr is available durinf build once installed
ENV PATH="${PATH}:/usr/local/texlive/${TEXLIVE_VERSION}/bin/x86_64-linux:/usr/local/texlive/${TEXLIVE_VERSION}/bin/aarch64-linux"
RUN <<EOF
    apt-get update -y
    apt-get install -y --no-install-recommends wget gnupg
    # Download and install TeX Live
    echo "Downloading TeX Live installer..."
    wget --progress=dot:giga -O install-tl.tar.gz ${TEXLIVE_MIRROR}/install-tl-unx.tar.gz || { echo "Failed to download TeX Live"; exit 1; }
    echo "Extracting TeX Live installer..."
    tar -xz --strip-components=1 -f install-tl.tar.gz
    echo "Starting TeX Live installation..."
    export TEXLIVE_INSTALL_NO_CONTEXT_CACHE=1
    export TEXLIVE_INSTALL_NO_WELCOME=1
    perl install-tl -profile tl.profile --location ${TEXLIVE_MIRROR} || { echo "TeX Live installation failed"; exit 1; }
    echo "TeX Live installation completed."

    # install additional latex packages
    echo "Installing additional LaTeX packages (latexmk, latexindent)..."
    tlmgr install latexmk latexindent
    echo "Additional packages installed."
    texhash

    # Clean up
    echo "Cleaning up TeX Live build artifacts..."
    rm -rf /usr/local/texlive/${TEXLIVE_VERSION}/texmf-var/web2c/*.log
    rm -rf /usr/local/texlive/${TEXLIVE_VERSION}/*.log
    apt-get remove -y wget gnupg
    apt-get clean autoclean
    apt-get autoremove -y
    rm -rf /var/lib/apt/lists/* /tmp/*
EOF
COPY texmf-local /usr/local/texlive/texmf-local


# Stage 3: Build Oh My Posh
FROM debian:${DEBIAN_VERSION} AS ohmyposh-builder
RUN <<EOF
    apt-get update -y
    apt-get install -y --no-install-recommends curl ca-certificates unzip
    # Install Oh My Posh
    echo "Installing Oh My Posh..."
    curl -s https://ohmyposh.dev/install.sh | bash -s -- -d /usr/local/bin  || { echo "Failed to install Oh My Posh"; exit 1; }
    echo "Oh My Posh installed."
    apt-get remove -y curl ca-certificates unzip
    apt-get clean autoclean
    apt-get autoremove -y
    rm -rf /var/lib/apt/lists/* /var/cache/*
EOF
COPY config/ohmyposh-theme.json /tmp/ohmyposh/theme.omp.json

# Stage 4: Final image
FROM debian:${DEBIAN_VERSION} AS main
ARG TEXLIVE_VERSION
ARG USER_UID
ARG USER_GID
ARG USER_NAME

# Copy artifacts from previous stages
COPY --from=texlive-builder /usr/local /usr/local
COPY --from=chktex-builder /tmp/chktex /usr/local/bin/chktex
COPY --from=ohmyposh-builder /usr/local/bin /usr/local/bin

# Set TeX Live PATH
ENV PATH="${PATH}:/usr/local/texlive/${TEXLIVE_VERSION}/bin/x86_64-linux:/usr/local/texlive/${TEXLIVE_VERSION}/bin/aarch64-linux"

# Install dependencies and configure environment
RUN <<EOF
    apt-get update -y
    apt-get install -y --no-install-recommends \
        openssh-client \
        git \
        python3 \
        locales \
        python3-pygments \
        gnuplot \
        poppler-utils \
        imagemagick \
        tzdata \
        sudo
    ln -s /usr/bin/python3 /usr/bin/python

    # Create non-root user with sanitized username
    groupadd --gid $USER_GID $USER_NAME || true
    useradd --uid $USER_UID --gid $USER_GID -m  -s /bin/bash $USER_NAME || true

    # add user to sudoers for adminnistrative tasks
    echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USER_NAME
    chmod 0440 /etc/sudoers.d/$USER_NAME
    chown root:root /etc/sudoers.d/${USER_NAME}

    mkdir -p "/home/${USER_NAME}/.ohmyposh" "/home/${USER_NAME}/.latexindent" "/home/${USER_NAME}/.ssh"
    echo "Host *" >> /home/${USER_NAME}/.ssh/config
    echo "  ForwardAgent yes" >> /home/${USER_NAME}/.ssh/config
    echo "export TERM=xterm" >> /home/${USER_NAME}/.bashrc
    chown -R $USER_UID:$USER_GID "/home/${USER_NAME}"

    # Configure Oh My Posh
    printf "eval \"\$(oh-my-posh --init --shell bash --config /home/${USER_NAME}/.ohmyposh/theme.omp.json)\"\n" >> "/home/${USER_NAME}/.bashrc"

    # Set locale
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    sed -i -e 's/# de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen
    dpkg-reconfigure --frontend=noninteractive locales



    # Clean up
    apt-get clean autoclean
    apt-get autoremove -y
    rm -rf /var/lib/apt/lists/* /var/cache/* /tmp/*
EOF


# Copy configuration files to non-root user's home
COPY config/latexindent-config.yaml "/home/${USER_NAME}/.indentconfig.yaml"
COPY config/latexindent-settings.yaml "/home/${USER_NAME}/.latexindent/defaultSettings.yaml"
COPY config/chktex-config.rc "/home/${USER_NAME}/.chktexrc"
COPY config/ohmyposh-theme.json "/home/${USER_NAME}/.ohmyposh/theme.omp.json"
RUN chown -R $USER_UID:$USER_GID "/home/$USER_NAME"

# Set default user and working directory
USER "${USER_NAME}"
WORKDIR "/home/${USER_NAME}"

# prepare font database
RUN <<EOF
    luaotfload-tool --update --force -vvv || { echo "Failed to generate font database"; exit 1; }
EOF


