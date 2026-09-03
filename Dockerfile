FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive
ENV USER=rust
ENV HOME=/home/rust
ENV SERVER_DIR=/home/rust/server
ENV LD_LIBRARY_PATH=/home/rust/server:/home/rust/server/RustDedicated_Data/Plugins/x86_64

RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl lib32gcc-s1 lib32stdc++6 libc6-i386 tini dos2unix gosu \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash ${USER}

RUN mkdir -p /opt/steamcmd && \
    curl -sSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar -xz -C /opt/steamcmd && \
    chmod +x /opt/steamcmd/steamcmd.sh && \
    printf '#!/bin/sh\nexec /opt/steamcmd/steamcmd.sh "$@"\n' > /usr/local/bin/steamcmd && \
    chmod +x /usr/local/bin/steamcmd && \
    chown -R ${USER}:${USER} /opt/steamcmd ${HOME}

COPY entrypoint.sh /entrypoint.sh
RUN dos2unix /entrypoint.sh && chmod +x /entrypoint.sh

WORKDIR ${HOME}

RUN steamcmd +force_install_dir ${SERVER_DIR} +login anonymous +app_update 258550 validate +quit && \
    mkdir -p ${HOME}/.steam/sdk64 ${HOME}/.steam/sdk32 && \
    ln -sf ${SERVER_DIR}/steamclient.so ${HOME}/.steam/sdk64/steamclient.so && \
    ln -sf ${SERVER_DIR}/steamclient.so ${HOME}/.steam/sdk32/steamclient.so && \
    chown -R ${USER}:${USER} ${HOME} ${SERVER_DIR}

VOLUME ${SERVER_DIR}/server/rust
EXPOSE 28015/tcp 28015/udp 28017/tcp 28082/tcp

ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]