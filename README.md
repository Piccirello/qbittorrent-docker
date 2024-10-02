# qbittorrent-docker
Build libtorrent 2 and qBittorrent 5 from source in Docker on Ubuntu 24.04. qBittorrent runs as user 1001.

This project also builds Qt6 from source due to the version of Qt6 in Ubuntu's package repo not being recent enough.

## Usage

This project can be used to build qBittorrent, libtorrent, or both. Specify the desired version(s) by modifying the `QBITTORRENT_VERSION` and `LIBTORRENT_VERSION` variables in `build.sh`.

```bash
$ build.sh [qbittorrent|libtorrent|all]
```

You can modify the build behavior using various flags.

|Flag   | Behavior  |
|---|---|
| `--no-push` | Don't push the built image(s) to Docker Hub |
| `--no-latest` | Don't tag the build image(s) w/ `latest` |
| `--master` | Build the master branch, ignoring the `QBITTORRENT_VERSION` value. |

