ARG BASE_IMAGE
FROM $BASE_IMAGE

ENV TZ "America/Los_Angeles"
ENV DEBIAN_FRONTEND=noninteractive

ENV PATH "/usr/local/lib:${PATH}"
ENV LD_LIBRARY_PATH /usr/local/lib

ARG QT_PACKAGE

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
    && /tmp/qt-installer.run --root /usr/src/qt --accept-licenses --accept-obligations --default-answer --confirm-command --auto-answer telemetry-question=No install "$QT_PACKAGE"
