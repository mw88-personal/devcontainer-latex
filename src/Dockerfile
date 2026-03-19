# syntax=docker/dockerfile:1.4

#  debian version for builders
ARG DEBIAN_VERSION=12.11-slim

# global user configuration
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG USER_NAME=dev


# Stage 1: Build Oh My Posh
FROM debian:${DEBIAN_VERSION} AS ohmyposh-builder
RUN <<EOF
    apt-get update -y
    apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        unzip
    # Install Oh My Posh
    echo "Installing Oh My Posh..."
    curl -s https://ohmyposh.dev/install.sh | bash -s -- -d /usr/local/bin  || { echo "Failed to install Oh My Posh"; exit 1; }
    echo "Oh My Posh installed."
EOF
# COPY config/ohmyposh-theme.json /tmp/ohmyposh/theme.omp.json

# Stage 2: Final image (Basiert nun auf dem aktualisierten qmcgaw Image)
FROM qmcgaw/latexdevcontainer:latest-full AS main

ARG USER_UID
ARG USER_GID
ARG USER_NAME

# Copy artifacts from previous stages
COPY --from=ohmyposh-builder /usr/local/bin/oh-my-posh /usr/local/bin/oh-my-posh

# Installiere Python, Manim-Abhängigkeiten und deine Zusatztools
RUN <<EOF
    apt-get update -y
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y --no-install-recommends \
        openssh-client \
        git \
        nano \
        locales \
        tzdata \
        sudo \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        python3-pygments \
        build-essential \
        ffmpeg \
        libcairo2-dev \
        libpango1.0-dev \
        pkg-config \
        gnuplot \
        poppler-utils \
        imagemagick \
        ghostscript

    ln -s /usr/bin/python3 /usr/bin/python

    # ImageMagick Policy anpassen (erlaubt PDF-Verarbeitung)
    sed -i 's/<policy domain="coder" rights="none" pattern="PDF" \/>/<policy domain="coder" rights="read|write" pattern="PDF" \/>/g' /etc/ImageMagick-6/policy.xml

    # Create non-root user with sanitized username
    groupadd --gid $USER_GID $USER_NAME || true
    useradd --uid $USER_UID --gid $USER_GID -m  -s /bin/bash $USER_NAME || true

    # add user to sudoers for adminnistrative tasks
    mkdir -p /etc/sudoers.d
    echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USER_NAME
    chmod 0440 /etc/sudoers.d/$USER_NAME
    chown root:root /etc/sudoers.d/${USER_NAME}

    # Configure Oh My Posh
    echo "export TERM=xterm" >> /home/${USER_NAME}/.bashrc
    echo 'if [ -f /ws/.config/ohmyposh-theme.json ]; then' >> /home/${USER_NAME}/.bashrc
    echo '    eval "$(oh-my-posh init bash --config /ws/.config/ohmyposh-theme.json)"' >> /home/${USER_NAME}/.bashrc
    echo 'elif [ -f /ws/src/config/ohmyposh-theme.json ]; then' >> /home/${USER_NAME}/.bashrc
    echo '    eval "$(oh-my-posh init bash --config /ws/src/config/ohmyposh-theme.json)"' >> /home/${USER_NAME}/.bashrc
    echo 'elif [ -f /home/'${USER_NAME}'/.ohmyposh-theme.json ]; then' >> /home/${USER_NAME}/.bashrc
    echo '    eval "$(oh-my-posh init bash --config /home/'${USER_NAME}'/.ohmyposh-theme.json)"' >> /home/${USER_NAME}/.bashrc
    echo 'else' >> /home/${USER_NAME}/.bashrc
    echo '    eval "$(oh-my-posh init bash)"' >> /home/${USER_NAME}/.bashrc
    echo 'fi' >> /home/${USER_NAME}/.bashrc


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
# COPY config/latexindent-config.yaml "/home/${USER_NAME}/.indentconfig.yaml"
# COPY config/latexindent-settings.yaml "/home/${USER_NAME}/.latexindent/defaultSettings.yaml"
COPY config/chktex-config-default.rc "/home/${USER_NAME}/.chktexrc"
# NEU: copy the Oh My Posh Theme as ultimate Fallback into the home directory
COPY config/ohmyposh-theme.json "/home/${USER_NAME}/.ohmyposh-theme.json"
RUN chown -R $USER_UID:$USER_GID "/home/$USER_NAME"


# Set default user and working directory
USER "${USER_NAME}"
WORKDIR "/home/${USER_NAME}"

# prepare font database
RUN <<EOF
    luaotfload-tool --update --force -vvv || { echo "Failed to generate font database"; exit 1; }
EOF


