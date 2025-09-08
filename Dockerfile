# syntax=docker/dockerfile:1
FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 python3.10-venv python3-pip \
    build-essential ffmpeg git wget ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set Python aliases
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1 && \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

WORKDIR /app

# Copy only dependency files first for better caching
COPY pyproject.toml README.md LICENSE /app/
COPY src /app/src
COPY gradio_tts_app.py gradio_vc_app.py multilingual_app.py /app/

# Create venv (optional but keeps global clean)
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python deps
# Use official torch CUDA wheels matching CUDA 12.1
RUN pip install --upgrade pip setuptools wheel && \
    pip install --index-url https://download.pytorch.org/whl/cu121 \
      torch==2.6.0 torchaudio==2.6.0 && \
    pip install -e .

# Gradio listens on 7860
EXPOSE 7860

# Default to multilingual app
ENV GRADIO_SERVER_NAME=0.0.0.0 \
    GRADIO_SERVER_PORT=7860

CMD ["python", "multilingual_app.py"]