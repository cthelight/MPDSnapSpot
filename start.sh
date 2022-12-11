#! /bin/bash
ulimit -l 65535

# If configs exist, use them, otherwise run with the defaults (generally do not work)
[ -f /config/mpd.conf ] && ln -sf /config/mpd.conf /etc/mpd.conf
[ -f /config/snapserver.conf ] && ln -sf /config/snapserver.conf /etc/snapserver.conf

snapserver &
# avahi-daemon &
mpd --stdout --no-daemon /etc/mpd.conf &

wait -n

exit $?
