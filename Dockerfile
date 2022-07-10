FROM python:3.8 as libbuilder
WORKDIR /app
RUN python3.8 -m venv /app/venv 
ENV VIRTUAL_ENV=/app/venv 
RUN /app/venv/bin/pip install \
    numpy \
    torch torchvision --extra-index-url https://download.pytorch.org/whl/cu116 \
    discoart #IPython

# .cache/discoart, ~/.cache/clip

FROM nvidia/cuda:11.6.2-cudnn8-devel-ubuntu20.04

# Set bash as default shell
ENV SHELL=/bin/bash

# Create a working directory
WORKDIR /app/

# Build with some basic utilities

RUN apt-get update && apt-get install -y \
    python3-pip \
    apt-utils \
    git wget \
    && apt-get autoremove -y \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/

# alias python='python3'
RUN ln -s /usr/bin/python3 /usr/bin/python
COPY --from=libbuilder /app/venv/lib/python3.8/site-packages /app/

COPY ./discoart/ /app/discoart/
RUN python3 -c "import discoart; discoart.create(steps=2, diffusion_sampling_mode='plms', width_height=[10, 10])" || true
