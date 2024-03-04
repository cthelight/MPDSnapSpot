FROM debian:bookworm-slim AS builder

RUN apt update
RUN apt install pkg-config libasound2-dev curl build-essential libpulse-dev libvorbisidec-dev libvorbis-dev libopus-dev libflac-dev libsoxr-dev alsa-utils libavahi-client-dev avahi-daemon libexpat1-dev libboost-dev git npm -y

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y

ENV PATH="/root/.cargo/bin:${PATH}"

RUN cargo install --root /usr librespot
WORKDIR /
RUN git clone https://github.com/badaix/snapcast.git
WORKDIR /snapcast
RUN git checkout v0.27.0
RUN make -j $(nproc --all)
RUN cp server/snapserver /snapserver

# Also build snapweb
WORKDIR /
RUN git clone https://github.com/badaix/snapweb.git
WORKDIR /snapweb
RUN git checkout v0.6.0-beta.2
RUN npm ci && npm run build
RUN cp -r build /snapweb_out





FROM debian:bookworm-slim

# Steal relevant binaries from builder
COPY --from=builder /snapserver /usr/bin/snapserver
COPY --from=builder /usr/bin/librespot /usr/bin/librespot

# Steal snapweb website contents from builder (snapserver.conf needs to point here)
COPY --from=builder /snapweb_out /usr/share/snapserver/snapweb

# Install necessary SW

RUN apt update && apt install mpd -y && apt clean -y

RUN echo '@audio - memlock unlimited >> /etc/security/limits.conf'

COPY start.sh start.sh

# Location for user to mount mpd.conf and snapserver.conf, and location for MPD data
RUN mkdir /config /data
# Snapserver stores persistent data in .config. Override that to go to /data
RUN ln -s /data /root/.config
# Start the services via shell script
CMD ./start.sh
