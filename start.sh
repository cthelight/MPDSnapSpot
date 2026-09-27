#!/usr/bin/env bash
# Entrypoint: starts snapserver and MPD in the foreground and makes sure both
# are terminated (and reaped) when the container stops or either service dies.
#
# tini (see ENTRYPOINT in the Dockerfile) is PID 1 and forwards SIGTERM/SIGINT
# to this script; the traps below then signal both services and wait for them
# to exit, so `docker stop` results in a graceful shutdown.
set -u

# librespot/ALSA may want more locked memory; raise it if the runtime allows.
ulimit -l 65535 2>/dev/null || true

# Use mounted configs when present, otherwise fall back to the built-in
# defaults (which generally do not match a real setup).
MPD_CONF=/etc/mpd.conf
SNAP_CONF=/etc/snapserver.conf
[ -f /config/mpd.conf ] && MPD_CONF=/config/mpd.conf
[ -f /config/snapserver.conf ] && SNAP_CONF=/config/snapserver.conf

SNAP_PID=""
MPD_PID=""

shutdown() {
    [ -n "$SNAP_PID" ] && kill "$SNAP_PID" 2>/dev/null
    [ -n "$MPD_PID" ] && kill "$MPD_PID" 2>/dev/null
    # Wait for both to exit so shutdown is clean and no zombies are left.
    wait 2>/dev/null
}
trap shutdown EXIT
trap 'exit 143' INT TERM

snapserver --config "$SNAP_CONF" &
SNAP_PID=$!
mpd --no-daemon "$MPD_CONF" &
MPD_PID=$!

# Exit as soon as either service stops, propagating its exit status so the
# container (and any orchestrator) notices.
wait -n
