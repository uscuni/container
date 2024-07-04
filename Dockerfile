FROM quay.io/jupyter/minimal-notebook

LABEL maintainer="Martin Fleischmann <martin.fleischmann@natur.cuni.cz>"
LABEL org.opencontainers.image.source = "https://github.com/uscuni/container"

# Set version
ENV DOCKER_ENV_VERSION "24.7"

USER $NB_UID

# Install packages
ADD ./environment.yml /home/${NB_USER}/
RUN mamba env update -f environment.yml -n base && \
    mamba clean --all -f -y && \
    rm ./environment.yml && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# disable Jupyter announcements
RUN jupyter labextension disable "@jupyterlab/apputils-extension:announcements"

# Import matplotlib the first time to build the font cache.
ENV XDG_CACHE_HOME="/home/${NB_USER}/.cache/"
RUN MPLBACKEND=Agg python -c "import matplotlib.pyplot" && \
    fix-permissions "/home/${NB_USER}"

# Install bottom, a Rust alternative of htop

USER root
RUN curl -LO https://github.com/ClementTsang/bottom/releases/download/0.9.6/bottom_0.9.6_amd64.deb && \
    dpkg -i bottom_0.9.6_amd64.deb && \
    rm bottom_0.9.6_amd64.deb

# Switch back to user to avoid accidental container runs as root
USER $NB_UID

# Install code server extensions
RUN code-server --install-extension ms-python.python \
    && code-server --install-extension ms-toolsai.jupyter \
    && code-server --install-extension charliermarsh.ruff \
    && code-server --install-extension chrisjsewell.myst-tml-syntax
