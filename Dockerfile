
FROM debian:11

RUN apt update
RUN apt upgrade -y
RUN apt install mpd pkg-config libasound2-dev curl build-essential -y

RUN curl https://sh.rustup.rs -sSf | bash -s -- -y

ENV PATH="/root/.cargo/bin:${PATH}"
run cargo install --root /usr librespot

RUN curl -L -O https://github.com/badaix/snapcast/releases/download/v0.26.0/snapserver_0.26.0-1_amd64.deb
RUN apt install ./snapserver_0.26.0-1_amd64.deb -y

RUN echo '@audio - memlock unlimited >> /etc/security/limits.conf'

COPY start.sh start.sh

# Location for user to mount mpd.conf and snapserver.conf
RUN mkdir /config
# Location to use for MPD data (assuming mpd.conf is correctly configured)
RUN mkdir /data

CMD ./start.sh
