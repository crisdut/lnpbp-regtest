# Builder
FROM alpine:3.14 as builder

ARG SOURCE_CODE=https://github.com/crisdut/bitcoin.git
ARG BUILDER_SOURCE=/opt/src
ARG BUILDER_DIR=/opt/bitcoin
ARG BITCOIN_VERSION=v23.0rc2

RUN apk add \
    autoconf \
    automake \
    boost-dev \
    build-base \
    sqlite-dev \
    chrpath \
    file \
    gnupg \
    libevent-dev \
    libressl \
    libtool \
    linux-headers \
    zeromq-dev \
    clang \
    wget \
    git

WORKDIR $BUILDER_DIR
WORKDIR $BUILDER_SOURCE
RUN git clone $SOURCE_CODE

WORKDIR $BUILDER_SOURCE/bitcoin
RUN git checkout $BITCOIN_VERSION

RUN ./autogen.sh
RUN ./configure \
    LDFLAGS=-L`ls -d /opt/db*`/lib/ CPPFLAGS=-I`ls -d /opt/db*`/include/ \
    # Enable Fuzz tests
    # CC=clang CXX=clang++ \
    # --enable-c++17 --enable-fuzz --with-sanitizers=address,fuzzer,undefined \
    --prefix=${BUILDER_DIR} \
    --mandir=/usr/share/man \
    --disable-tests \
    --disable-bench \
    --disable-ccache \
    --with-gui=no \
    --with-utils \
    --with-libs \
    --with-daemon \
    --with-sqlite \
    --without-bdb

RUN make -j "$(($(nproc)+1))"
RUN make install

# Runtime
FROM alpine:3.14 as runtime
ENV BITCOIN_PREFIX=/opt/bitcoin
ENV PATH=${BITCOIN_PREFIX}/bin:$PATH
ENV BITCOIN_DATA=/home/bitcoin/.bitcoin
ENV USER=bitcoin

RUN adduser -S ${USER}
RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/https\:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories
RUN apk --no-cache add \
  boost-filesystem \
  boost-system \
  boost-thread \
  libevent \
  libzmq \
  bash \
  su-exec \
  sqlite-dev &&  rm -rf /var/cache/apk/*

COPY --from=builder /opt/bitcoin /opt/bitcoin
COPY docker-entrypoint.sh /entrypoint.sh

VOLUME ["/home/bitcoin/.bitcoin"]
RUN bitcoind -version | grep "Bitcoin Core version v${BITCOIN_VERSION}"

# rpc
EXPOSE 18444/tcp
# p2p
EXPOSE 18443/tcp

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bitcoind"]
