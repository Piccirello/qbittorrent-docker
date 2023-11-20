#!/bin/bash
set -euo pipefail

# CONFIG

BASE_IMAGE="ubuntu:22.04"

# libtorrent
LIBTORRENT_DOCKER_FILE="./libtorrent.dockerfile"
LIBTORRENT_IMAGE_NAME="piccirello/libtorrent"
LIBTORRENT_MAJOR_VERSION="1"
LIBTORRENT_MINOR_VERSION="2"
LIBTORRENT_PATCH_VERSION="19"
LIBTORRENT_VERSION="$LIBTORRENT_MAJOR_VERSION.$LIBTORRENT_MINOR_VERSION.$LIBTORRENT_PATCH_VERSION"

# qBittorrent
QBITTORRENT_DOCKER_FILE="./qbittorrent.dockerfile"
QBITTORRENT_IMAGE_NAME="piccirello/qbittorrent"
QBITTORRENT_MAJOR_VERSION="4"
QBITTORRENT_MINOR_VERSION="6"
QBITTORRENT_PATCH_VERSION="0"
QBITTORRENT_VERSION="$QBITTORRENT_MAJOR_VERSION.$QBITTORRENT_MINOR_VERSION.$QBITTORRENT_PATCH_VERSION"

# platforms to build for
PLATFORMS="linux/amd64,linux/arm64"

# END CONFIG

TAG_WITH_LATEST="true"
PUSH_IMAGES="--push"

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
done

# run
if [ "$command" == "all" ] || [ "$command" == "libtorrent" ]; then
  echo "Updating $BASE_IMAGE base image"
  docker pull "$BASE_IMAGE"

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
  echo "Building qbittorrent $QBITTORRENT_VERSION"
  docker buildx build \
    -f "$QBITTORRENT_DOCKER_FILE" \
    -t "$QBITTORRENT_IMAGE_NAME:$QBITTORRENT_VERSION" \
    -t "$QBITTORRENT_IMAGE_NAME:$QBITTORRENT_MAJOR_VERSION.$QBITTORRENT_MINOR_VERSION" \
    ${TAG_WITH_LATEST:+ -t "$QBITTORRENT_IMAGE_NAME:latest"} \
    --build-arg BASE_IMAGE="$LIBTORRENT_IMAGE_NAME:$LIBTORRENT_VERSION" \
    --build-arg VERSION="$QBITTORRENT_VERSION" \
    --platform "$PLATFORMS" \
    $PUSH_IMAGES \
    .
fi
