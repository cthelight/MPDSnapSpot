FROM debian:buster-slim AS builder

RUN apt update
RUN apt install pkg-config libasound2-dev curl build-essential -y

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y

RUN curl -L https://github.com/badaix/snapcast/releases/download/v0.27.0/snapserver_0.27.0-1_amd64.deb -o /snapserver.deb

ENV PATH="/root/.cargo/bin:${PATH}"

RUN cargo install --root /usr librespot



FROM debian:buster-slim

# Steal relevant binaries from builder
COPY --from=builder /snapserver.deb /snapserver.deb
COPY --from=builder /usr/bin/librespot /usr/bin/librespot

# Install necessary SW

RUN apt update && apt install mpd -y && apt install /snapserver.deb -y && apt clean -y

RUN echo '@audio - memlock unlimited >> /etc/security/limits.conf'

COPY start.sh start.sh

# Location for user to mount mpd.conf and snapserver.conf, and location for MPD data
RUN mkdir /config /data

# Start the services via shell script
CMD ./start.sh
