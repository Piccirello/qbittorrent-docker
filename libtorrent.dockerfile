ARG BASE_IMAGE=ubuntu:20.04
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
    g++ \
    libarchive-tools \
    libboost-chrono-dev \
    libboost-python-dev \
    libboost-random-dev \
    libboost-system-dev \
    libssl-dev \
    libtool \
    make \
    wget

WORKDIR /usr/src/libtorrent

ARG LIBTORRENT_SRC=https://github.com/arvidn/libtorrent/releases/download/v${VERSION}/libtorrent-rasterbar-${VERSION}.tar.gz

# TODO verify download SHA256
# download libtorrent
RUN wget -q $LIBTORRENT_SRC -O libtorrent.tar.gz \
    && bsdtar --strip-components=1 -xzf libtorrent.tar.gz \
    && rm libtorrent.tar.gz

# build and install
RUN autoreconf -fi \
    && ./configure CXXFLAGS=-std=c++17 \
    && make -j$(nproc) \
    && make install

FROM $BASE_IMAGE

WORKDIR /usr/src/libtorrent

COPY --from=0 /usr/local/lib /usr/local/lib/
COPY --from=0 /usr/local/include/libtorrent /usr/local/include/libtorrent
