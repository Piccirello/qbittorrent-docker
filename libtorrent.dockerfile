ARG BASE_IMAGE
FROM $BASE_IMAGE

ENV TZ "America/Los_Angeles"
ENV DEBIAN_FRONTEND=noninteractive

ENV PATH "/usr/local/lib:${PATH}"
ENV LD_LIBRARY_PATH /usr/local/lib

RUN apt-get update && apt-get install -y \
    libboost-tools-dev \
    libboost-dev \
    libboost-system-dev \
    g++ \
    libarchive-tools \
    libssl-dev \
    libtool \
    wget

ARG VERSION
ARG LIBTORRENT_SRC=https://github.com/arvidn/libtorrent/releases/download/v${VERSION}/libtorrent-rasterbar-${VERSION}.tar.gz

WORKDIR /usr/src/libtorrent

# TODO verify download SHA256
# download libtorrent
RUN wget -q $LIBTORRENT_SRC -O libtorrent.tar.gz --secure-protocol=TLSv1_2 --https-only \
    && bsdtar --strip-components=1 -xzf libtorrent.tar.gz \
    && rm libtorrent.tar.gz

# build and install
RUN echo "using gcc ;" >>~/user-config.jam \
    && b2 crypto=openssl cxxstd=17 release \
    && b2 install --prefix=/usr/local

FROM $BASE_IMAGE

WORKDIR /usr/src/libtorrent

COPY --from=0 /usr/local/lib /usr/local/lib/
COPY --from=0 /usr/local/include/libtorrent /usr/local/include/libtorrent
