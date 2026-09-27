MPDSnapSpot

This repo contains the info required to create the MPDSnapSpot docker container, which can be used as an MPD+Spotify endpoint, and stream audio to any number of endpoints simultaneously via snapcast.

When running this docker container, you should be able to attach snapcast clients to the snap server, such that they all play the audio stream. Additionally, you should be able to control the mpd server, and the spotify connect endpoint such that the audio is streamed over the snapcast connections.

Services & ports
 - MPD: TCP 6600 (music player control)
 - Snapserver HTTP/RPC + snapweb web UI: TCP 1780
 - Snapserver audio stream: TCP 1789

Running the container
 - Mount a directory containing `mpd.conf` and `snapserver.conf` in the `/config` dir when launching the container
     - An example set of configs are provided in `example_configs`
     - If a config is missing, the built-in default for that service is used (generally does not match a real setup)
 - Mount a directory in the container to be used by MPD for data
     - No specific mount point in the container is necessary, as the directory used is specified in `mpd.conf`
     - I usually use `/data` for obvious reasons
 - Mount a directory in the container containing your music for MPD to utilize
     - Also no specific mount point required here, as this is also configured in the MPD config file

NOTE: The contents of the `snapweb` browser-based configuration/status tool are located at the default `/usr/share/snapserver/snapweb`. To make this available, ensure port 1780 is exposed, and your http doc_root in your `snapserver.conf` is pointing at that location.

Non-root user and volume permissions
 - The container runs as the unprivileged `mpd` user (uid/gid 125, matching Debian's mpd package).
 - Host directories mounted into the container (`/data`, your music dir, ...) must be readable/writable by uid 125, e.g. `chown -R 125:125 /path/to/data /path/to/music`.
 - `/data` holds MPD state (db, playlists, ...) and snapserver's persistent data (`/data/snapserver/`).

Signals & shutdown
 - `tini` is PID 1 and the entrypoint traps SIGTERM/SIGINT: on `docker stop`, snapserver (and any librespot it spawned) and MPD receive SIGTERM and are waited for, so shutdown is graceful and exits quickly within the default 10s stop timeout.
 - If either service exits on its own, the container exits with that service's exit status, so orchestrators can restart it.

Healthcheck
 - A healthcheck TCP-probes MPD (127.0.0.1:6600) and snapserver (127.0.0.1:1780). If your configs use different ports, override with `-e MPD_HEALTH_PORT=<port> -e SNAPSERVER_HEALTH_PORT=<port>`.

Memory locking (optional)
 - The entrypoint raises the memlock ulimit when allowed. If you run librespot with an ALSA output (mmap) and see buffer issues, start the container with `--ulimit memlock=-1`.

Building
 - Requires Docker with BuildKit (default in current Docker releases).
 - `make build` — build for the host platform (loads into the local daemon).
 - `make build_tag TAG=1.0.0` — same, with a tag.
 - `make multiarch_build_tag TAG=1.0.0` — build linux/amd64, linux/arm64/v8, linux/arm/v7 and push (multi-arch images cannot be loaded into a local daemon). `PLATFORMS` can be overridden.
 - All component versions are pinned via ARGs at the top of the Dockerfile (`SNAPCAST_VERSION`, `SNAPWEB_VERSION`, `LIBRESPOT_VERSION`, `RUST_TOOLCHAIN`).
 - librespot is compiled from the pinned release with a committed, frozen dependency tree (`vendor/librespot-<version>/Cargo.lock`). After bumping `LIBRESPOT_VERSION`, regenerate it with `make librespot-lock LIBRESPOT_VERSION=<version>`.

Image variants
  - `Dockerfile` (default): glibc on `debian:trixie-slim`. The safe, battle-tested build.
  - `Dockerfile.alpine` (`make build_alpine`, `make build_alpine_tag`, `make multiarch_build_tag_alpine`): musl on `alpine:3.23`, roughly 3x smaller (325 MB vs 933 MB). The Debian image's size is dominated by the mpd package's dependency tree (full ffmpeg stack, libicu, ...); Alpine's mpd (0.24.8, newer than trixie's 0.24.4) resolves to a much tighter closure. The cost: snapserver and librespot are compiled for musl (all of their native deps are packaged on Alpine), and `bash` is added to the runtime so the shared `start.sh`/healthcheck work unchanged.

Huge shoutout to the following projects to make this possible:
 - https://github.com/snapcast/snapcast
 - https://github.com/badaix/snapweb
 - https://www.musicpd.org/
 - https://github.com/librespot-org/librespot
