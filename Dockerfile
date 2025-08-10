FROM python:3.12-bookworm

LABEL org.opencontainers.image.authors="stefan@nitsche.se"
LABEL version="1.0"
LABEL description="Custom Beets image for Unraid"

ARG BEETS_VERSION
ARG SUPERCRONIC_VERSION=0.2.29
ARG SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.29/supercronic-linux-amd64
ARG SUPERCRONIC=supercronic-linux-amd64
ARG SUPERCRONIC_SHA1SUM=cd48d45c4b10f3f0bfdd3a57d054cd05ac96812b

ENV BEETS_VERSION=${BEETS_VERSION} \
    BEETS_CONFIG=/config/config.yaml \
    S6_VERSION=v3.2.1.0 \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_KEEP_ENV=1 \
    S6_STAGE2_HOOK="/apply_services_conditions.sh" \
    TZ="Europe/Stockholm"

# Install s6-overlay (v3)
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-noarch.tar.xz /tmp/
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-x86_64.tar.xz /tmp/
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz && \
    rm /tmp/s6-overlay-*.tar.xz

# Install system dependencies
RUN DEBIAN_FRONTEND=noninteractive useradd -m -d /usr/share/app -s /usr/sbin/nologin -g users -u 99 app && \
    curl -fsSLO "$SUPERCRONIC_URL" && \
    echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - && \
    chmod +x "$SUPERCRONIC" && \
    mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" && \
    ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic && \
    DEBIAN_FRONTEND=noninteractive ACCEPT_EULA=Y apt-get update && apt-get install -y --no-install-recommends \
        tzdata \
        nano \
        rsync \
        ffmpeg \
        libchromaprint-tools \
        shntool \
        cuetools \
        flac \
        mp3val \
        libmagickwand-dev \
        curl \
        ca-certificates \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create venv for Beets & install pip and Beets inside venv
RUN python -m venv /opt/beets && \
    /opt/beets/bin/pip install --no-cache-dir --upgrade pip setuptools && \
    /opt/beets/bin/pip install --no-cache-dir \
        beets[autobpm,chroma,embedart,embyupdate,fetchart,kodiupdate,lyrics,lastgenre,lastimport,plexupdate,replaygain,sonosupdate,web,discogs]==${BEETS_VERSION} \
        beets-extrafiles \
        beetcamp \
        git+https://github.com/edgars-supe/beets-importreplace.git

# Setup directories
RUN mkdir -p /data /config /logs

VOLUME /data /config /logs

# Add s6 services
COPY rootfs/ /

ENTRYPOINT ["/init"]

# Set PATH to use venv by default
ENV PATH="/opt/beets/bin:/command:$PATH"
