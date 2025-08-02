FROM python:3.12-bookworm

ARG BEETS_VERSION
ENV BEETS_VERSION=${BEETS_VERSION}

# Install system dependencies
RUN apt-get update && apt-get install -y \
    ffmpeg \
    shntool \
    cuetools \
    flac \
    libmagickwand-dev \
    cron \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install s6-overlay (v3)
ENV S6_VERSION=v3.1.4.1
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-noarch.tar.xz /tmp/
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-x86_64.tar.xz /tmp/
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz && \
    rm /tmp/s6-overlay-*.tar.xz

# Create venv for Beets
RUN python -m venv /opt/beets

# Install pip and Beets inside venv
RUN /opt/beets/bin/pip install --no-cache-dir --upgrade pip setuptools && \
    /opt/beets/bin/pip install --no-cache-dir beets[all]==${BEETS_VERSION} \
    git+https://github.com/edgars-supe/beets-importreplace.git

# Setup directories
ENV BEETS_CONFIG /config/config.yaml
RUN mkdir -p /data /config /logs

VOLUME /data /config /logs

# Add s6 services
COPY rootfs/ /

ENTRYPOINT ["/init"]

# Set PATH to use venv by default
ENV PATH="/opt/beets/bin:$PATH"
