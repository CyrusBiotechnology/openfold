ARG CUDA=12.1.1
FROM nvidia/cuda:${CUDA}-cudnn8-runtime-ubuntu20.04

# metainformation
LABEL org.opencontainers.image.version = "1.0.0"
LABEL org.opencontainers.image.authors = "Gustaf Ahdritz"
LABEL org.opencontainers.image.source = "https://github.com/aqlaboratory/openfold"
LABEL org.opencontainers.image.licenses = "Apache License 2.0"
LABEL org.opencontainers.image.base.name="docker.io/nvidia/cuda:10.2-cudnn8-runtime-ubuntu18.04"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-key del 7fa2af80
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/3bf863cc.pub

RUN apt-get update && apt-get install -y wget libxml2 cuda-minimal-build-12-1 libcusparse-dev-12-1 libcublas-dev-12-1 libcusolver-dev-12-1 git
RUN wget -P /tmp \
    "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" \
    && bash /tmp/Miniconda3-latest-Linux-x86_64.sh -b -p /opt/conda \
    && rm /tmp/Miniconda3-latest-Linux-x86_64.sh
ENV PATH /opt/conda/bin:$PATH

# COPY environment.yml /opt/openfold/environment.yml

# installing into the base environment since the docker container wont do anything other than run openfold
# RUN conda env update -n base --file /opt/openfold/environment.yml && conda clean --all

RUN conda config --add channels conda-forge \
  && conda config --add channels bioconda \
  && conda config --add channels pytorch \
  && conda config --add channels nvidia \

RUN conda install -c conda-forge setuptools=59.5.0 pip openmm=7.7 pdbfixer
RUN conda install -c bioconda hmmer=3.3.2 hhsuite=3.3.0 kalign2=2.04
RUN conda install -c pytorch pytorch=2.1.0
RUN conda install -c nvidia cuda-toolkit=12.1.1

RUN conda run pip install biopython==1.79 \
    deepspeed==0.5.10 \
    dm-tree==0.1.6 \
    ml-collections==0.1.0 \
    numpy==1.21.2 \
    PyYAML==5.4.1 \
    requests==2.26.0 \
    scipy==1.7.1 \
    tqdm==4.62.2 \
    typing-extensions \
    pytorch_lightning==2.1.4 \
    wandb==0.12.21 \
    git+https://github.com/NVIDIA/dllogger.git

COPY openfold /opt/openfold/openfold
COPY scripts /opt/openfold/scripts
COPY run_pretrained_openfold.py /opt/openfold/run_pretrained_openfold.py
COPY train_openfold.py /opt/openfold/train_openfold.py
COPY setup.py /opt/openfold/setup.py
COPY lib/openmm.patch /opt/openfold/lib/openmm.patch
RUN wget -q -P /opt/openfold/openfold/resources \
    https://git.scicore.unibas.ch/schwede/openstructure/-/raw/7102c63615b64735c4941278d92b554ec94415f8/modules/mol/alg/src/stereo_chemical_props.txt
RUN patch -p0 -d /opt/conda/lib/python3.7/site-packages/ < /opt/openfold/lib/openmm.patch
WORKDIR /opt/openfold
RUN python3 setup.py install
