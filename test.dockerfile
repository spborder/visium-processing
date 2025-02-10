FROM satijalab/seurat:5.0.0

RUN apt-get update
RUN apt-get install -y libv8-dev
RUN apt-get install -y libbz2-dev
RUN apt-get install -y liblzma-dev

RUN mkdir lzf
WORKDIR /lzf
RUN wget https://raw.githubusercontent.com/h5py/h5py/3.0.0/lzf/lzf_filter.c https://raw.githubusercontent.com/h5py/h5py/3.0.0/lzf/lzf_filter.h
RUN mkdir lzf
WORKDIR /lzf/lzf
RUN wget https://raw.githubusercontent.com/h5py/h5py/3.0.0/lzf/lzf/lzf_c.c https://raw.githubusercontent.com/h5py/h5py/3.0.0/lzf/lzf/lzf_d.c https://raw.githubusercontent.com/h5py/h5py/3.0.0/lzf/lzf/lzfP.h https://raw.githubusercontent.com/h5py/h5py/3.0.0/lzf/lzf/lzf.h
WORKDIR /lzf
RUN gcc -O2 -fPIC -shared lzf/*.c lzf_filter.c -I /usr/include/hdf5/serial/ -lhdf5_serial -o liblzf_filter.so
WORKDIR /
ENV HDF5_PLUGIN_PATH=/lzf

RUN git clone https://github.com/satijalab/azimuth.git
RUN ls -la

COPY Rprofile.site /usr/local/lib/R/etc/Rprofile.site

RUN R --no-echo -e "BiocManager::install(c('BSgenome.Hsapiens.UCSC.hg38', 'glmGamPoi', 'GenomeInfoDb', 'GenomicRanges', 'TFBSTools', 'JASPAR2020', 'EnsDb.Hsapiens.v86', 'IRanges', 'Rsamtools', 'S4Vectors'), force = TRUE)"

RUN R --no-echo -e "install.packages('sp', repos='http://cran.us.r-project.org')"
RUN R --no-echo -e "install.packages('Matrix', repos='http://R-Forge.R-project.org')"
RUN R --no-echo -e "install.packages(c('data.table', 'DT', 'future', 'ggplot2',  'googlesheets4', 'hdf5r', 'htmltools', 'httr', 'patchwork', 'rlang', 'shiny', 'shinyBS', 'shinydashboard', 'shinyjs', 'Signac', 'stringr', 'withr'), repo='https://cloud.r-project.org')"
RUN R --no-echo -e "remotes::install_github(c('immunogenomics/presto', 'mojaveazure/seurat-disk', 'satijalab/seurat-data'), dependencies = FALSE)"

ARG AZIMUTH_VER=unknown
RUN echo "$AZIMUTH_VER"
COPY . /root/azimuth
RUN R --no-echo -e "install.packages('/root/azimuth', repos = NULL, type = 'source')"

EXPOSE 3838

CMD ["R", "-e", "Azimuth::AzimuthApp(reference='/reference-data')"]