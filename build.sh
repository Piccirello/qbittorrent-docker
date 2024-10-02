#!/bin/bash
set -euo pipefail

### CONFIG ###

BASE_IMAGE="ubuntu:24.04"

# libtorrent
LIBTORRENT_DOCKER_FILE="./libtorrent.dockerfile"
LIBTORRENT_IMAGE_NAME="piccirello/libtorrent"
LIBTORRENT_VERSION="2.0.10"

# qBittorrent
QBITTORRENT_DOCKER_FILE="./qbittorrent.dockerfile"
QBITTORRENT_IMAGE_NAME="piccirello/qbittorrent"
QBITTORRENT_VERSION="5.0.0"
QBITTORRENT_RELEASE_SRC="https://github.com/qbittorrent/qBittorrent/archive/release-${QBITTORRENT_VERSION}.tar.gz"
QBITTORRENT_MASTER_SRC="https://github.com/qbittorrent/qBittorrent/archive/refs/heads/master.tar.gz"

# Used for building Qt due to Ubuntu's package repository not containing a recent enough version of Qt6
QT_DOCKER_FILE="./libtorrent-qt.dockerfile"
QT_VERSION="6.7.1"
QT_IMAGE_NAME="piccirello/libtorrent-qt"

# platforms to build for
PLATFORMS="linux/amd64"

### END CONFIG ###

TAG_WITH_LATEST="true"
USE_MASTER=""
PUSH_IMAGES="--push"

# shellcheck disable=SC2206
LIBTORRENT_VERSION_ARR=(${LIBTORRENT_VERSION//./ })
LIBTORRENT_MAJOR_VERSION="${LIBTORRENT_VERSION_ARR[0]}"
LIBTORRENT_MINOR_VERSION="${LIBTORRENT_VERSION_ARR[1]}"
LIBTORRENT_PATCH_VERSION="${LIBTORRENT_VERSION_ARR[2]}"

# shellcheck disable=SC2206
QBITTORRENT_VERSION_ARR=(${QBITTORRENT_VERSION//./ })
QBITTORRENT_MAJOR_VERSION="${QBITTORRENT_VERSION_ARR[0]}"
QBITTORRENT_MINOR_VERSION="${QBITTORRENT_VERSION_ARR[1]}"
QBITTORRENT_PATCH_VERSION="${QBITTORRENT_VERSION_ARR[2]}"

QT_VERSION_WO_DOTS="${QT_VERSION//.}"

# parse command
if [ $# -eq 0 ]; then
  command=""
else
  command="$1"
fi

VALID_COMMANDS=(all libtorrent qbittorrent)
# shellcheck disable=SC2076
if [[ ! " ${VALID_COMMANDS[*]} " =~ " ${command} " ]]; then
  echo -n "Invalid command, must be one of ( "
  printf "%s " "${VALID_COMMANDS[@]}"
  echo ")"
  exit 1
fi

# parse args
for arg; do
  if [ "$arg" = "--no-latest" ]; then
    TAG_WITH_LATEST=""
  fi

  if [ "$arg" = "--no-push" ]; then
    # load the image into the local registry
    PUSH_IMAGES="--load"
  fi

  if [ "$arg" = "--master" ]; then
    USE_MASTER="true"
  fi
done

echo "=== Configuration ==="
echo "Base image: $BASE_IMAGE"
echo "Platform(s): $PLATFORMS"
echo "Push image: $([[ "$PUSH_IMAGES" = "--push" ]] && echo yes || echo no)"
echo "Tag w/ latest: $([[ "$TAG_WITH_LATEST" = "true" ]] && echo yes || echo no)"
echo "Use master branch: $([[ "$USE_MASTER" = "true" ]] && echo yes || echo no)"
echo "=== END Configuration ==="
echo ""

# run
if [ "$command" == "all" ] || [ "$command" == "libtorrent" ]; then
  echo "Updating $BASE_IMAGE base image"
  docker pull "$BASE_IMAGE"

  if [[ "$USE_MASTER" = "true" ]]; then
    echo "Building libtorrent master branch is not currently supported"
    exit 1
  fi

  echo "Building libtorrent $LIBTORRENT_VERSION"
  docker buildx build \
    -f "$LIBTORRENT_DOCKER_FILE" \
    -t "$LIBTORRENT_IMAGE_NAME:$LIBTORRENT_VERSION" \
    -t "$LIBTORRENT_IMAGE_NAME:$LIBTORRENT_MAJOR_VERSION.$LIBTORRENT_MINOR_VERSION" \
    ${TAG_WITH_LATEST:+ -t "$LIBTORRENT_IMAGE_NAME:latest"} \
    --build-arg BASE_IMAGE="$BASE_IMAGE" \
    --build-arg VERSION="$LIBTORRENT_VERSION" \
    --platform "$PLATFORMS" \
    $PUSH_IMAGES \
    .
fi

if [ "$command" == "all" ] || [ "$command" == "qbittorrent" ]; then
  qt_image="$QT_IMAGE_NAME:$LIBTORRENT_VERSION-$QT_VERSION"
  docker pull "$qt_image" --platform "$PLATFORMS"

  # only build Qt image if it doesn't already exist
  # this allows skipping this step, which requires qtaccount.ini to exist
  if ! docker image inspect "$qt_image" >/dev/null 2>&1; then
    echo "Building Qt6"
    docker buildx build \
      -f "$QT_DOCKER_FILE" \
      -t "$qt_image" \
      --build-arg BASE_IMAGE="$LIBTORRENT_IMAGE_NAME:$LIBTORRENT_VERSION" \
      --build-arg QT_PACKAGE="qt.qt6.$QT_VERSION_WO_DOTS.linux_gcc_64" \
      --secret id=qtaccount,src=./qtaccount.ini \
      --platform "$PLATFORMS" \
      $PUSH_IMAGES \
      .
  fi

  QBITTORRENT_SRC="$QBITTORRENT_RELEASE_SRC"
  if [[ "$USE_MASTER" = "true" ]]; then
    TAG_WITH_LATEST=""
    QBITTORRENT_VERSION="master"
    QBITTORRENT_MAJOR_VERSION="master"
    QBITTORRENT_MINOR_VERSION="$(date "+%Y-%m-%d")"
    QBITTORRENT_SRC="$QBITTORRENT_MASTER_SRC"
  fi

  echo "Building qbittorrent $QBITTORRENT_VERSION"
  docker buildx build \
    -f "$QBITTORRENT_DOCKER_FILE" \
    -t "$QBITTORRENT_IMAGE_NAME:$QBITTORRENT_VERSION" \
    -t "$QBITTORRENT_IMAGE_NAME:$QBITTORRENT_MAJOR_VERSION.$QBITTORRENT_MINOR_VERSION" \
    ${TAG_WITH_LATEST:+ -t "$QBITTORRENT_IMAGE_NAME:latest"} \
    --build-arg BASE_IMAGE="$QT_IMAGE_NAME:$LIBTORRENT_VERSION-$QT_VERSION" \
    --build-arg QT_VERSION="$QT_VERSION" \
    --build-arg QBITTORRENT_SRC="$QBITTORRENT_SRC" \
    --platform "$PLATFORMS" \
    $PUSH_IMAGES \
    .
fi
