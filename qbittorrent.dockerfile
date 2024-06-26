ARG BASE_IMAGE
FROM $BASE_IMAGE

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
    qtbase5-dev \
    qt5-qmake \
    qtbase5-dev-tools \
    qtbase5-private-dev \
    qttools5-dev-tools \
    wget \
    zlib1g-dev

ARG VERSION
ARG QBITTORRENT_SRC=https://github.com/qbittorrent/qBittorrent/archive/release-${VERSION}.tar.gz

WORKDIR /usr/src/qbittorrent

# download qbittorrent
RUN wget -q $QBITTORRENT_SRC -O qbittorrent.tar.gz --secure-protocol=TLSv1_2 --https-only \
    && bsdtar --strip-components=1 -xzf ./qbittorrent.tar.gz \
    && rm qbittorrent.tar.gz

ENV CXXFLAGS "-std=c++17"

# build and install
RUN ./configure --prefix=/usr --disable-gui --enable-stacktrace \
    && make -j$(nproc) \
    && make install

FROM $BASE_IMAGE

ENV PATH "/usr/local/lib:${PATH}"
ENV LD_LIBRARY_PATH /usr/local/lib

WORKDIR /usr/src/qbittorrent

RUN apt-get update && apt-get install -y \
    libboost-python1.74.0 \
    libboost-system1.74.0 \
    libqt5network5 \
    libqt5sql5 \
    libqt5xml5 \
    libssl3 \
    python3 \
    # used by completion scripts
    curl \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=0 /usr/local/lib/libtorrent-rasterbar.* /usr/local/lib/
COPY --from=0 /usr/bin/qbittorrent-nox /usr/bin/qbittorrent-nox

# setup non-root user
RUN useradd --shell /bin/bash --create-home qbtuser --uid 1001 \
    && mkdir /config /data /downloads \
    && chown qbtuser: /config /data /downloads

USER qbtuser

ENV XDG_CONFIG_HOME="/config" \
    XDG_DATA_HOME="/data"

ENTRYPOINT ["bash", "-c"]
CMD ["/usr/bin/qbittorrent-nox"]
