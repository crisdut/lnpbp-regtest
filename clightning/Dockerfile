FROM debian:buster-slim as bitcoin-builder

ARG SOURCE_CODE=https://github.com/crisdut/bitcoin.git
ARG BUILDER_SOURCE=/opt/src
ARG BUILDER_DIR=/opt/bitcoin
ARG BITCOIN_VERSION=v24.0

RUN apt-get update -qq && \
    apt-get install -qq -y --no-install-recommends \
        build-essential \
        ca-certificates \
        autoconf \
        automake \
        chrpath \
        file \
        dirmngr \
        gettext \
        gnupg \
        pkg-config \
        libevent-dev \
        libpq-dev \
        libtool \
        libffi-dev \
        libsqlite3-dev \
        libboost-dev \
        libboost-chrono-dev libboost-filesystem-dev libboost-program-options-dev libboost-system-dev \
        libboost-test-dev libboost-thread-dev \
        git wget net-tools

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

FROM debian:buster-slim as lightning-builder
ENV SOURCE_CODE=https://github.com/crisdut/lightning.git

ENV BUILDER_SOURCE=/opt/src
ENV BUILDER_DIR=/opt/lightning

ENV DEVELOPER=0
ENV PYTHON_VERSION=3
ENV LIGHTNING_VERSION=v22.11

RUN apt-get update -qq && \
    apt-get install -qq -y --no-install-recommends \
        autoconf \
        automake \
        build-essential \
        ca-certificates \
        curl \
        dirmngr \
        gettext \
        git \
        gnupg \
        libpq-dev \
        libtool \
        libffi-dev \
        python3 \
        python3-dev \
        python3-mako \
        python3-pip \
        python3-venv \
        python3-setuptools \
        wget

RUN wget -q https://zlib.net/zlib-1.2.13.tar.gz \
&& tar xvf zlib-1.2.13.tar.gz \
&& cd zlib-1.2.13 \
&& ./configure \
&& make \
&& make install && cd .. && rm zlib-1.2.13.tar.gz && rm -rf zlib-1.2.13

RUN apt-get install -y --no-install-recommends unzip tclsh \
&& wget -q https://www.sqlite.org/2019/sqlite-src-3290000.zip \
&& unzip sqlite-src-3290000.zip \
&& cd sqlite-src-3290000 \
&& ./configure --enable-static --disable-readline --disable-threadsafe --disable-load-extension \
&& make \
&& make install && cd .. && rm sqlite-src-3290000.zip && rm -rf sqlite-src-3290000

RUN wget -q https://gmplib.org/download/gmp/gmp-6.1.2.tar.xz \
&& tar xvf gmp-6.1.2.tar.xz \
&& cd gmp-6.1.2 \
&& ./configure --disable-assembly \
&& make \
&& make install && cd .. && rm gmp-6.1.2.tar.xz && rm -rf gmp-6.1.2

WORKDIR $BUILDER_DIR
WORKDIR $BUILDER_SOURCE
RUN git clone $SOURCE_CODE

WORKDIR $BUILDER_SOURCE/lightning
RUN git checkout $LIGHTNING_VERSION
RUN git submodule update --init --recursive

RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/install-poetry.py | python3 - \
    && pip3 install -U pip \
    && pip3 install -U wheel \
    && pip3 install -U mako Mako \
    && /root/.local/bin/poetry config virtualenvs.create false \
    && /root/.local/bin/poetry install

RUN ./configure --prefix=${BUILDER_DIR} --enable-static
RUN make -j "$(($(nproc)+1))" DEVELOPER=${DEVELOPER}
RUN make install

# Runtime
FROM debian:buster-slim as runtime
ENV BITCOIN_PREFIX=/opt/bitcoin
ENV LIGHTNING_PREFIX=/opt/lightning
ENV PATH=${BITCOIN_PREFIX}/bin:${LIGHTNING_PREFIX}/bin:$PATH
ENV USER=lightning

ENV LIGHTNINGD_DATA=/home/lightning/.lightning
ENV LIGHTNINGD_NETWORK=bitcoin
ENV LIGHTNINGD_RPC_PORT=9835
ENV LIGHTNINGD_PORT=9735

RUN adduser ${USER}

RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
    socat inotify-tools python3 python3-pip libpq5 \
    libboost-filesystem-dev libevent-dev \
    && rm -rf /var/lib/apt/lists/*

# USER ${USER}
VOLUME ["/home/lightning/.lightning"]

WORKDIR "/home/lightning/"
COPY --from=bitcoin-builder --chown=${USER}:${USER} ${BITCOIN_PREFIX} ${BITCOIN_PREFIX}
COPY --from=lightning-builder --chown=${USER}:${USER} ${LIGHTNING_PREFIX} ${LIGHTNING_PREFIX}
COPY docker-entrypoint.sh entrypoint.sh

EXPOSE 9735 9736 9835 9836 19735 19736 19835 19836

ENTRYPOINT ["./entrypoint.sh"]
CMD ["lightningd"]