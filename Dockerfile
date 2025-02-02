ARG PQUEUE_VERSION
FROM pqueue:$PQUEUE_VERSION as pqueue


FROM python:3.10 as libbuilder
WORKDIR /app
RUN python3.10 -m venv /app/venv 
ENV VIRTUAL_ENV=/app/venv 
RUN /app/venv/bin/pip install torch torchvision --extra-index-url https://download.pytorch.org/whl/cu116 
RUN /app/venv/bin/pip install \
    numpy \
    lpips \
    ftfy \
    pyyaml \
    open_clip_torch \
    pyspellchecker \
    rich \
    TwitterAPI "psycopg[pool, binary]" requests 

# ideally we multistage
FROM python:3.10 as cache
WORKDIR /app
RUN pip install discoart
RUN python3.10 -c "import discoart; discoart.create(steps=2, diffusion_sampling_mode='plms', width_height=[4, 4])" || true

FROM nvidia/cuda:11.6.2-cudnn8-devel-ubuntu20.04

# Set bash as default shell
ENV SHELL=/bin/bash

# Create a working directory
WORKDIR /app/

# Build with some basic utilities

ENV DEBIAN_FRONTEND="noninteractive"
RUN apt-get update && apt-get install -y software-properties-common \ 
  && add-apt-repository ppa:deadsnakes/ppa \ 
  && apt-get install -y python3.10 python3.10-venv git wget apt-utils \
  && apt-get remove -y python3.8 python3-minimal \
  && apt-get autoremove -y \
  && rm -rf /var/lib/{apt,dpkg,cache,log}/

COPY --from=cache /root/.cache/ /root/.cache/
COPY --from=libbuilder /app/venv/lib/python3.10/site-packages /app/
RUN mkdir /app/output
COPY ./discoart/ /app/discoart/
RUN python3.10 -c "import discoart; discoart.create(steps=3, diffusion_sampling_mode='plms')" || true
COPY ./pqueue.py ./config.py ./run.py /app/
ENV DISCOART_LOG_LEVEL="DEBUG"
ENTRYPOINT ["/usr/bin/python3.10", "/app/run.py"]
