# syntax=docker/dockerfile:1.4

ARG DEBIAN_VERSION=12.4-slim
ARG TEXLIVE_VERSION=2023
ARG TEXLIVE_MIRROR=http://ctan.math.utah.edu/ctan/tex-archive/systems/texlive/tlnet

# build chktex in temporary container
FROM debian:${DEBIAN_VERSION}  as chktex-builder
ARG CHKTEX_VERSION=1.7.8
WORKDIR /tmp/chktex
RUN <<EOF
    apt-get update -y
    apt-get install -y --no-install-recommends build-essential ca-certificates make wget
    wget -qO- http://download.savannah.gnu.org/releases/chktex/chktex-${CHKTEX_VERSION}.tar.gz | tar -xz --strip-components=1
    ./configure
    make
    mv chktex /tmp
    rm -r *
EOF


# build texlive in temporary container
FROM perl:5.38 AS texlive-builder
WORKDIR /tmp/texlive
ARG SCHEME=scheme-basic
ARG DOCFILES=0
ARG SRCFILES=0
ARG TEXLIVE_VERSION TEXLIVE_VERSION
ARG TEXLIVE_MIRROR TEXLIVE_MIRROR

COPY config/texlive${TEXLIVE_VERSION}.profile tl.profile
# the installation of cpan modules is separated, such that rebuilding time is lower: this part does not change as often, so it does not need to be rebuilt on every build
RUN <<EOF
    # install perl dependencies
    cpan -i Bundle::LWP Log::Dispatch::File   YAML::Tiny   File::HomeDir
EOF
# download and install texlive
# add the path, so tlmgr is available durinf build once installed
ENV PATH="${PATH}:/usr/local/texlive/${TEXLIVE_VERSION}/bin/x86_64-linux:/usr/local/texlive/${TEXLIVE_VERSION}/bin/aarch64-linux"
RUN <<EOF
    apt-get update -y
    apt-get install -y --no-install-recommends wget gnupg
    wget -qO- ${TEXLIVE_MIRROR}/install-tl-unx.tar.gz | tar -xz --strip-components=1
    export TEXLIVE_INSTALL_NO_CONTEXT_CACHE=1
    export TEXLIVE_INSTALL_NO_WELCOME=1
    perl install-tl -profile tl.profile --location ${TEXLIVE_MIRROR}


    # install additional latex packages
    tlmgr install latexmk latexindent

    texhash

    rm /usr/local/texlive/${TEXLIVE_VERSION}/texmf-var/web2c/*.log
    # rm /usr/local/texlive/${TEXLIVE_VERSION}/tlpkg/texlive.tlpdb.main.*

    apt-get remove -y wget
    apt-get clean autoclean
    apt-get autoremove -y
    rm -rf /var/lib/apt/lists/*
    # rm -rf /var/lib/{apt,dpkg,cache,log}/ /tmp/texlive /usr/local/texlive/${TEXLIVE_VERSION}/*.log
    rm -rf /usr/local/texlive/${TEXLIVE_VERSION}/*.log
    rm -rf /usr/local/share/*
EOF


# FROM debian:${DEBIAN_VERSION} as git-builder

# WORKDIR /tmp/builder




# FROM perl:5.28-slim
# COPY --from=builder /usr/local/lib/perl5 /usr/local/lib/perl5

FROM debian:${DEBIAN_VERSION} AS main

ARG TEXLIVE_VERSION TEXLIVE_VERSION

COPY --from=chktex-builder /tmp/chktex /usr/local/bin/chktex
COPY --from=texlive-builder /usr/local /usr/local
COPY config/.indentconfig.yaml /root/.indentconfig.yaml
COPY config/defaultSettings.yaml /root/.latexindent/defaultSettings.yaml


ENV PATH="${PATH}:/usr/local/texlive/${TEXLIVE_VERSION}/bin/x86_64-linux:/usr/local/texlive/${TEXLIVE_VERSION}/bin/aarch64-linux"

# add git and ssh support
RUN <<EOF
    apt-get update -y
    apt-get install -y --no-install-recommends openssh-client git
    apt-get clean autoclean
    apt-get autoremove -y
    rm -rf /var/lib/apt/lists/*
EOF


