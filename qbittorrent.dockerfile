ARG BASE_IMAGE
FROM $BASE_IMAGE

ENV TZ="America/Los_Angeles"
ENV DEBIAN_FRONTEND=noninteractive

ARG QT_VERSION

ENV PATH="/usr/local/lib:${PATH}"
ENV CMAKE_PREFIX_PATH="/usr/src/qt/$QT_VERSION/gcc_64/"
ENV LD_LIBRARY_PATH="/usr/src/qt/$QT_VERSION/gcc_64/lib"

ARG QBITTORRENT_SRC

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

ENV PATH="/usr/local/lib:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/lib"
ENV QT_PLUGIN_PATH="/usr/local/plugins"

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
    && apt remove -y \
        libqt6network6t64 \
        libqt6sql6t64 \
        libqt6xml6t64 \
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
