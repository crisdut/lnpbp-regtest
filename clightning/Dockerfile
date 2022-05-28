# Build stage for BerkeleyDB
FROM alpine as berkeleydb

RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/https\:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories
RUN apk --no-cache add autoconf
RUN apk --no-cache add automake
RUN apk --no-cache add build-base
RUN apk --no-cache add libressl

ENV BERKELEYDB_VERSION=db-4.8.30.NC
ENV BERKELEYDB_PREFIX=/opt/${BERKELEYDB_VERSION}

RUN wget https://download.oracle.com/berkeley-db/${BERKELEYDB_VERSION}.tar.gz
RUN tar -xzf *.tar.gz
RUN sed s/__atomic_compare_exchange/__atomic_compare_exchange_db/g -i ${BERKELEYDB_VERSION}/dbinc/atomic.h
RUN mkdir -p ${BERKELEYDB_PREFIX}

WORKDIR /${BERKELEYDB_VERSION}/build_unix

RUN ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=${BERKELEYDB_PREFIX}
RUN make -j4
RUN make install
RUN rm -rf ${BERKELEYDB_PREFIX}/docs

# Build stage for Bitcoin Core
FROM alpine as downloader

COPY --from=berkeleydb /opt /opt

RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/https\:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories
RUN apk --no-cache add autoconf
RUN apk --no-cache add automake
RUN apk --no-cache add boost-dev
RUN apk --no-cache add build-base
RUN apk --no-cache add sqlite-dev
RUN apk --no-cache add chrpath
RUN apk --no-cache add file
RUN apk --no-cache add gnupg
RUN apk --no-cache add libevent-dev
RUN apk --no-cache add libressl
RUN apk --no-cache add libtool
RUN apk --no-cache add linux-headers
RUN apk --no-cache add zeromq-dev
RUN set -ex \
  && for key in \
    0CCBAAFD76A2ECE2CCD3141DE2FFD5B1D88CA97D \
    152812300785C96444D3334D17565732E08E5E41 \
    0AD83877C1F0CD1EE9BD660AD7CC770B81FD22A8 \
    590B7292695AFFA5B672CBB2E13FC145CD3F4304 \
    28F5900B1BB5D1A4B6B6D1A9ED357015286A333D \
    637DB1E23370F84AFF88CCE03152347D07DA627C \
    CFB16E21C950F67FA95E558F2EEB9F5CC09526C1 \
    6E01EEC9656903B0542B8F1003DB6322267C373B \
    D1DBF2C4B96F2DEBF4C16654410108112E7EA81F \
    82921A4B88FD454B7EB8CE3C796C4109063D4EAF \
    9DEAE0DC7063249FB05474681E4AED62986CD25D \
    9D3CC86A72F8494342EA5FD10A41BDC3F4FAFF1C \
    74E2DEF5D77260B98BC19438099BAD163C70FBFA \
  ; do \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" || \
    gpg --batch --keyserver keys.openpgp.org --recv-keys "$key" || \
    gpg --batch --keyserver keyserver.pgp.com --recv-keys "$key" || \
    gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" ; \
  done

ENV BITCOIN_VERSION=22.0
ENV BITCOIN_PREFIX=/opt/bitcoin-${BITCOIN_VERSION}

RUN wget https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/SHA256SUMS
RUN wget https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/SHA256SUMS.asc
RUN wget https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}.tar.gz
RUN gpg --verify SHA256SUMS.asc SHA256SUMS
RUN grep " bitcoin-${BITCOIN_VERSION}.tar.gz\$" SHA256SUMS | sha256sum -c -
RUN tar -xzf *.tar.gz

WORKDIR /bitcoin-${BITCOIN_VERSION}

RUN sed -i '/AC_PREREQ/a\AR_FLAGS=cr' src/univalue/configure.ac
RUN sed -i '/AX_PROG_CC_FOR_BUILD/a\AR_FLAGS=cr' src/secp256k1/configure.ac
RUN sed -i s:sys/fcntl.h:fcntl.h: src/compat.h
RUN ./autogen.sh
RUN ./configure LDFLAGS=-L`ls -d /opt/db*`/lib/ CPPFLAGS=-I`ls -d /opt/db*`/include/ \
    --prefix=${BITCOIN_PREFIX} \
    --mandir=/usr/share/man \
    --disable-tests \
    --disable-bench \
    --disable-ccache \
    --with-gui=no \
    --with-utils \
    --with-libs \
    --with-daemon
RUN make -j4
RUN make install

FROM debian:buster-slim as builder
ARG REPO=https://github.com/ElementsProject/lightning.git
ARG VERSION=v0.10.2
ARG USER=lightning
ARG DATA=/data

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates autoconf \
    automake build-essential git libtool python python3 python3-mako \
    wget gnupg dirmngr git gettext libgmp-dev libsqlite3-dev net-tools \
    zlib1g-dev unzip tclsh git libsodium-dev libpq-dev valgrind python3-pip \
    valgrind libpq-dev shellcheck cppcheck \
    libsecp256k1-dev jq \
    python3-setuptools \
    python3-dev
RUN pip3 install mrkd wheel mistune==0.8.4

ARG DEVELOPER=0

WORKDIR /opt
RUN git clone --recurse-submodules $REPO && \
    cd lightning && \
    ls -la && \
    mkdir -p /tmp/lightning_install && \
    ls -la /tmp && \
    git checkout $VERSION && \
    echo "Configuring" && \
    ./configure --prefix=/tmp/lightning_install \
        --enable-static && \
    echo "Building" && \
    make -j3 DEVELOPER=${DEVELOPER} && \
    echo "installing" && \
    make install && \
    ls -la  /tmp/lightning_install

FROM debian:buster-slim as final
ENV BITCOIN_VERSION=22.0
ENV BITCOIN_PREFIX=/opt/bitcoin-${BITCOIN_VERSION}
ARG REPO=https://github.com/ElementsProject/lightning.git
ARG VERSION=v0.10.2
ARG USER=lightning
ARG DATA=/data

LABEL maintainer="nolim1t (hello@nolim1t.co)"

RUN apt-get update && apt-get install -y --no-install-recommends git socat inotify-tools python3 python3-pip cargo \
    libpq-dev libsodium-dev nodejs npm \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /lib /lib
COPY --from=builder /tmp/lightning_install/ /usr/local/
COPY --from=downloader $BITCOIN_PREFIX/bin /usr/bin
COPY ./docker-entrypoint.sh entrypoint.sh
RUN chmod 755 entrypoint.sh

RUN mkdir /rust-plugin && \
    chown 1000.1000 /rust-plugin

RUN adduser --disabled-password \
    --home "$DATA" \
    --gecos "" \
    "$USER"
USER $USER 

ENV LIGHTNINGD_DATA=$DATA/.lightning
ENV LIGHTNINGD_RPC_PORT=9835
ENV LIGHTNINGD_PORT=9735
ENV LIGHTNINGD_NETWORK=bitcoin

EXPOSE 9735 9736 9835 9836 19735 19736 19835 19836

ENTRYPOINT  [ "./entrypoint.sh" ]
