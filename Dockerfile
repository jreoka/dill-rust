FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV USER=rust
ENV HOME=/home/rust
ENV SERVER_DIR=/home/rust/server

RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl lib32gcc-s1 lib32stdc++6 libc6-i386 tini dos2unix \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash ${USER}

# Install steamcmd
RUN mkdir -p /opt/steamcmd && \
    curl -sSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar -xz -C /opt/steamcmd && \
    ln -s /opt/steamcmd/steamcmd.sh /usr/local/bin/steamcmd && \
    chown -R ${USER}:${USER} /opt/steamcmd ${HOME}

# Copy and force Unix line endings (fixes Windows editing)
COPY entrypoint.sh /entrypoint.sh
RUN dos2unix /entrypoint.sh && chmod +x /entrypoint.sh && chown ${USER}:${USER} /entrypoint.sh

USER ${USER}
WORKDIR ${HOME}

# Initial official server install
RUN steamcmd +force_install_dir ${SERVER_DIR} +login anonymous +app_update 258550 validate +quit

VOLUME ${SERVER_DIR}/server/rust

EXPOSE 28015/tcp 28015/udp 28017/tcp 28082/tcp

ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]