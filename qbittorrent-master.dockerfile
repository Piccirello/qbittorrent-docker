ARG BASE_IMAGE
FROM $BASE_IMAGE

ENV TZ "America/Los_Angeles"
ENV DEBIAN_FRONTEND=noninteractive

ENV PATH "/usr/local/lib:${PATH}"
ENV LD_LIBRARY_PATH /usr/local/lib

ARG QT_VERSION
ARG QT_VERSION_WO_DOTS

RUN apt-get update && apt-get install -y \
    clang \
    cmake \
    gawk \
    g++ \
    gdb \
    libarchive-tools \
    libssl-dev \
    pkg-config \
    # version isn't recent enough (need >=6.5.0, these are 6.4)
    # libqt6svg6 \
    # qt6-base-dev \
    # qt6-base-dev-tools \
    autoconf \
    libboost-chrono-dev \
    libboost-python-dev \
    libboost-random-dev \
    libboost-system-dev \
    wget \
    zlib1g-dev

WORKDIR /usr/src/qt
RUN --mount=type=secret,id=qtaccount,target=/root/.local/share/Qt/qtaccount.ini \
    apt install -y \
        curl \
        gcc-11 \
        dbus \
        libfontconfig1-dev \
        libfreetype6-dev \
        libx11-dev \
        libx11-xcb-dev \
        libxext-dev \
        libxfixes-dev \
        libxi-dev \
        libxrender-dev \
        libxcb1-dev \
        libxcb-cursor-dev \
        libxcb-glx0-dev \
        libxcb-keysyms1-dev \
        libxcb-image0-dev \
        libxcb-shm0-dev \
        libxcb-icccm4-dev \
        libxcb-sync-dev \
        libxcb-xfixes0-dev \
        libxcb-shape0-dev \
        libxcb-randr0-dev \
        libxcb-render-util0-dev \
        libxcb-util-dev \
        libxcb-xinerama0-dev \
        libxcb-xkb-dev \
        libxkbcommon-dev \
        libxkbcommon-x11-dev \
        libgl1 \
    && curl -L -o "/tmp/qt-installer.run" "https://d13lb3tujbc8s0.cloudfront.net/onlineinstallers/qt-online-installer-linux-x64-4.8.0.run" \
    && chmod +x /tmp/qt-installer.run \
    && /tmp/qt-installer.run --root /usr/src/qt --accept-licenses --accept-obligations --default-answer --confirm-command --auto-answer telemetry-question=No install "qt.qt6.$QT_VERSION_WO_DOTS.linux_gcc_64"

ENV CMAKE_PREFIX_PATH "/usr/src/qt/$QT_VERSION/gcc_64/"
ENV LD_LIBRARY_PATH "/usr/src/qt/$QT_VERSION/gcc_64/lib"

ARG QBITTORRENT_SRC=https://github.com/qbittorrent/qBittorrent/archive/refs/heads/master.tar.gz

WORKDIR /usr/src/qbittorrent

# download qbittorrent
RUN wget -q $QBITTORRENT_SRC -O qbittorrent.tar.gz --secure-protocol=TLSv1_2 --https-only \
    && bsdtar --strip-components=1 -xzf ./qbittorrent.tar.gz \
    && rm qbittorrent.tar.gz

# build and install
RUN cmake -B build -DCMAKE_BUILD_TYPE=Release -DGUI=OFF \
    && cmake --build build \
    && cmake --install build

FROM $BASE_IMAGE

ARG QT_VERSION
ARG QT_VERSION_WO_DOTS

ENV PATH "/usr/local/lib:${PATH}"
ENV LD_LIBRARY_PATH "/usr/local/lib"
ENV QT_PLUGIN_PATH "/usr/local/plugins"

RUN apt-get update && apt-get install -y \
    libboost-python1.83.0 \
    libboost-system1.83.0 \
    libssl3 \
    python3 \
    # install these outdated Qt packages so that we get their dependencies. we'll override the actual Qt packages via LD_LIBRARY_PATH
    libqt6network6t64 \
    libqt6sql6t64 \
    libqt6xml6t64 \
    # used by completion scripts
    curl \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=0 /usr/local/lib/libtorrent-rasterbar.* /usr/local/lib/
COPY --from=0 \
    /usr/src/qt/$QT_VERSION/gcc_64/lib/libQt6Core.* \
    /usr/src/qt/$QT_VERSION/gcc_64/lib/libQt6DBus.* \
    /usr/src/qt/$QT_VERSION/gcc_64/lib/libQt6Network.* \
    /usr/src/qt/$QT_VERSION/gcc_64/lib/libQt6Sql.* \
    /usr/src/qt/$QT_VERSION/gcc_64/lib/libQt6Xml.* \
    /usr/src/qt/$QT_VERSION/gcc_64/lib/libicu* \
    /usr/local/lib/
COPY --from=0 /usr/src/qt/$QT_VERSION/gcc_64/plugins/ /usr/local/plugins/
COPY --from=0 /usr/local/bin/qbittorrent-nox /usr/local/bin/qbittorrent-nox

# setup non-root user
RUN useradd --shell /bin/bash --create-home qbtuser --uid 1001 \
    && mkdir /config /data /downloads \
    && chown qbtuser: /config /data /downloads

USER qbtuser

ENV XDG_CONFIG_HOME="/config" \
    XDG_DATA_HOME="/data"

ENTRYPOINT ["bash", "-c"]
CMD ["/usr/local/bin/qbittorrent-nox"]
