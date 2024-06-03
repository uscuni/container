FROM jupyter/minimal-notebook:latest

# Derived from darribas/gds_py for faster iteration

LABEL maintainer="Martin Fleischmann <martin.fleischmann@natur.cuni.cz>"
LABEL org.opencontainers.image.source = "https://github.com/uscuni/container"

# https://github.com/ContinuumIO/docker-images/blob/master/miniconda3/Dockerfile
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# Set version
ENV DOCKER_ENV_VERSION "24.6"

#--- Python ---#
ADD ./environment.yml /home/${NB_USER}/
RUN mamba env create -f environment.yml \
    && source activate uscuni \
    && python -m ipykernel install --user --name uscuni --display-name "uscuni-$DOCKER_ENV_VERSION" \
    && conda deactivate \
    && rm ./environment.yml \
    && conda clean --all --yes --force-pkgs-dirs \
    && find /opt/conda/ -follow -type f -name '*.a' -delete \
    && find /opt/conda/ -follow -type f -name '*.pyc' -delete \
    && find /opt/conda/ -follow -type f -name '*.js.map' -delete \
    && find /opt/conda/envs/uscuni//lib/python*/site-packages/bokeh/server/static \
    -follow -type f -name '*.js' ! -name '*.min.js' -delete \
    && pip cache purge \
    && rm -rf /home/$NB_USER/.cache/pip


# Make default
RUN jupyter lab --generate-config \
 && echo "c.MultiKernelManager.default_kernel_name='uscuni'" >> \
 /home/${NB_USER}/.jupyter/jupyter_lab_config.py \
 && echo "conda activate uscuni" >> /home/${NB_USER}/.bashrc \
 && echo "c.KernelSpecManager.ensure_native_kernel = False" >> \
 /home/${NB_USER}/.jupyter/jupyter_lab_config.py \
# https://github.com/jupyter/notebook/issues/3674#issuecomment-397212982
 && echo "c.KernelSpecManager.whitelist = {'uscuni'}" >> \
 /home/${NB_USER}/.jupyter/jupyter_lab_config.py
RUN jupyter kernelspec remove -y python3
ENV PATH="/opt/conda/envs/uscuni/bin/:${PATH}"

#--- Jupyter config ---#
USER root
# Turn off notifications
RUN jupyter labextension disable "@jupyterlab/apputils-extension:announcements" \
# Clean cache up
 && jupyter lab clean -y \
 && conda clean --all -f -y \
 && npm cache clean --force \
 && rm -rf $CONDA_DIR/share/jupyter/lab/staging \
 && rm -rf "/home/${NB_USER}/.node-gyp" \
 && rm -rf /home/$NB_USER/.cache/yarn \
# Fix permissions
 && fix-permissions "${CONDA_DIR}" \
 && fix-permissions "/home/${NB_USER}"
# Build mpl font cache
# https://github.com/jupyter/docker-stacks/blob/c3d5df67c8b158b0aded401a647ea97ada1dd085/scipy-notebook/Dockerfile#L59
USER $NB_UID
ENV XDG_CACHE_HOME="/home/${NB_USER}/.cache/"
RUN source activate uscuni \
 && MPLBACKEND=Agg python -c "import matplotlib.pyplot" && \
    fix-permissions "/home/${NB_USER}"

#--- htop ---#

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends htop \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Switch back to user to avoid accidental container runs as root
USER $NB_UID

RUN code-server --install-extension ms-python.python \
    && code-server --install-extension ms-toolsai.jupyter \
    && code-server --install-extension charliermarsh.ruff \
    && code-server --install-extension chrisjsewell.myst-tml-syntax
