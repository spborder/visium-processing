FROM satijalab/seurat:5.0.0

LABEL maintainer="Sam Border CMI Lab <samuel.border@medicine.ufl.edu>"


RUN apt-get update && \
    apt-get install --yes --no-install-recommends software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get --yes --no-install-recommends -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    git \
    wget \
    curl \
    ca-certificates \
    libcurl4-openssl-dev \
    libexpat1-dev \
    unzip \
    libhdf5-dev \
    libpython3-dev \
    python3.8-dev \
    python3.8-distutils \
    software-properties-common \
    libssl-dev \
    libffi-dev \
    # Standard build tools \
    build-essential \
    cmake \
    autoconf \
    automake \
    libtool \
    pkg-config \
    # useful later \
    libmemcached-dev && \
    #apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


RUN apt-get update ##[edited]

WORKDIR /
# Make Python3 the default and install pip.  Whichever is done last determines
# the default python version for pip.

# Make a specific version of python the default and install pip
RUN rm -f /usr/bin/python && \
    rm -f /usr/bin/python3 && \
    ln `which python3.8` /usr/bin/python && \
    ln `which python3.8` /usr/bin/python3 && \
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python get-pip.py && \
    rm get-pip.py
    #ln `which pip3` /usr/bin/pip 

RUN which  python && \
    python --version

RUN R -e 'devtools::install_github("satijalab/seurat","seurat5")'
RUN R -e 'devtools::install_github("satijalab/seurat-data","seurat5")'
RUN R -e 'BiocManager::install("glmGamPoi")'
RUN R -e 'BiocManager::install("TFBSTools")'
RUN R -e 'devtools::install_github("satijalab/azimuth","master")'
RUN R -e 'library(Seurat)'
ENV build_path=$PWD/build
ENV PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python

# Copying over plugin files
ENV plugin_path = visium-processing
RUN mkdir -p $plugin_path

RUN apt-get update && \
    apt-get install -y --no-install-recommends memcached && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY . $plugin_path
WORKDIR $plugin_path

RUN pip install --no-cache-dir --upgrade --ignore-installed pip setuptools && \
    pip install --no-cache-dir .  && \
    rm -rf /root/.cache/pip/*

# Show what was installed
RUN python --version && pip --version && pip freeze

# Defining entrypoint
WORKDIR $plugin_path/cli
LABEL entry_path=$plugin_path/cli

# Testing entrypoint
RUN python -m slicer_cli_web.cli_list_entrypoint --list_cli
RUN python -m slicer_cli_web.cli_list_entrypoint CellDeconvolution --help
RUN python -m slicer_cli_web.cli_list_entrypoint SpotAnnotation --help

ENV PYTHONBUFFERED=TRUE

ENTRYPOINT ["/bin/bash","docker-entrypoint.sh"]