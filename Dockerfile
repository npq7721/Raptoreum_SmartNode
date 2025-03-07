# Raptoreum Smartnode may 2022

# Use Ubuntu 20
FROM ubuntu:20.04

LABEL maintainer="tri"

ARG DEBIAN_FRONTEND=noninteractive
# Install packages
RUN apt-get update --fix-missing
RUN apt-get install --no-install-recommends -y apt-utils \
      ca-certificates \
      wget \
      curl \
      jq \
      pwgen \
      nano \
      unzip \
      psmisc \
      procps \
      build-essential libtool autotools-dev automake pkg-config python3 bsdmainutils cmake xz-utils git
RUN ( echo "12" && cat) | apt-get install cmake -y
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#check out and build raptoreum
RUN git clone https://github.com/Raptor3um/raptoreum
RUN cd raptoreum/depends && make -j10
RUN cd raptoreum && \
    ./autogen.sh && \
    ./configure --prefix=`pwd`/depends/x86_64-pc-linux-gnu --disable-tests --without-gui && \
    make -j10 && \
    cp src/raptoreum-cli src/raptoreum-tx src/raptoreumd /usr/local/bin && \
    rm -rf *
# Create dir to run datadir to bind for persistent data
VOLUME /raptoreum
WORKDIR /raptoreum

RUN mkdir /raptoreum/corefiles

COPY ./bootstrap.sh ./check.sh ./start.sh ./run_rtm_daemon.sh /usr/local/bin/
RUN chmod -R 755 /usr/local/bin

# Smartnode p2p port
EXPOSE 10226

# Use healthcheck to deal with hanging issues and prevent pose bans
HEALTHCHECK --start-period=10m --interval=15m --retries=3 --timeout=240s \
  CMD ["bash", "check.sh"]
CMD ["start.sh"]
