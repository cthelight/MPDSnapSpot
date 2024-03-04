MPDSnapSpot

This repo contains the info required to create the MPDSnapSpot docker container, which can be used as an MPD+Spotify endpoint, and stream audio to any number of endpoints simultaneously via snapcast.

When running this docker container, you should be able to attach snapcast clients to the snapcast server, such that they all play the audio stream. Additionally, you should be able to control the mpd server, and the spotify connect endpoint such that the audio is streamed over the snapcast connections.

To use this container you should do the following:
 - Mount a directory containing `mpd.conf` and `snapserver.conf` in the `/config` dir when launching the container
    - An example set of configs are provided in `example_configs`
 - Mount a directory in the container to be used by MPD for data
    - No specific mount point in the container is necessary, as the directory used is specified in `mpd.conf`
    - I usually use `/data` for obvious reasons
 - Mount a directory in the container containing your music for MPD to utilize
    - Also no specific mount point required here, as this is also configured in the MPD config file

NOTE: The contents of the `snapweb` browser-based configuration/status tool are located at the default `/usr/share/snapserver/snapweb`. To make this available, ensure port 1780 is exposed, and your http doc_root in your `snapserver.conf` is pointing at that location.

Huge shoutout to the following projects to make this possible:
 - https://github.com/badaix/snapcast
 - https://github.com/badaix/snapweb
 - https://www.musicpd.org/
 - https://github.com/librespot-org/librespot

