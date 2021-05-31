ARG BASE_IMAGE
FROM $BASE_IMAGE

ARG BUST_CACHE
ARG VERSION

RUN echo "Starting build"

# Ubuntu 20.04 workaround
ENV TZ "America/Los_Angeles"
ENV DEBIAN_FRONTEND=noninteractive

ENV PATH "/usr/local/lib:${PATH}"
ENV LD_LIBRARY_PATH /usr/local/lib

RUN apt-get update && apt-get install -y \
    autoconf \
    automake \
    clang \
    gawk \
    g++ \
    gdb \
    libarchive-tools \
    libboost-chrono-dev \
    libboost-python-dev \
    libboost-random-dev \
    libboost-system-dev \
    libqt5svg5-dev \
    libssl-dev \
    make \
    pkg-config \
    qt5-default \
    qttools5-dev-tools \
    wget \
    zlib1g-dev

WORKDIR /usr/src/qbittorrent

ARG QBITTORRENT_SRC=https://github.com/qbittorrent/qBittorrent/archive/release-${VERSION}.tar.gz

# TODO verify download SHA256
# download qbittorrent
RUN wget -q $QBITTORRENT_SRC -O qbittorrent.tar.gz \
    && bsdtar --strip-components=1 -xzf ./qbittorrent.tar.gz \
    && rm qbittorrent.tar.gz

# build and install
RUN ./configure --prefix=/usr --disable-gui \
    && make -j$(nproc) \
    && make install

FROM $BASE_IMAGE

ENV PATH "/usr/local/lib:${PATH}"
ENV LD_LIBRARY_PATH /usr/local/lib

WORKDIR /usr/src/qbittorrent

RUN apt-get update && apt-get install -y \
    libboost-python1.71.0 \
    libboost-system1.71.0 \
    libqt5network5 \
    libqt5xml5 \
    libssl1.1 \
    python3 \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=0 /usr/local/lib /usr/local/lib/
COPY --from=0 /usr/bin/qbittorrent-nox /usr/bin/qbittorrent-nox

# setup non-root user
RUN useradd --shell /bin/bash --create-home qbtuser \
    && mkdir /config /data /downloads \
    && chown qbtuser: /config /data /downloads

USER qbtuser

ENV XDG_CONFIG_HOME="/config" \
    XDG_DATA_HOME="/data"

ENTRYPOINT ["bash"]
CMD ["/usr/bin/qbittorrent-nox"]