FROM rust:1.61.0-slim-buster as builderstd
ARG BUILDER_DIR=/srv/rgb

RUN apt-get update \
    && apt-get -y install --no-install-recommends \
        wget build-essential cmake git pkg-config \
        libpq-dev libssl-dev libzmq3-dev libsqlite3-dev

WORKDIR $BUILDER_DIR
RUN cargo install rgb-std --version "=0.8.0-rc.2" \
        --locked --all-features --root "${BUILDER_DIR}"

FROM rust:1.61.0-slim-buster as builder
ARG SOURCE_CODE=https://github.com/crisdut/rgb-node.git
ARG BUILDER_SOURCE=/opt/src/rgb
ARG BUILDER_DIR=/srv/rgb
ARG VERSION=d36e4ad

RUN apt-get update \
    && apt-get -y install --no-install-recommends \
        wget build-essential cmake git pkg-config \
        libpq-dev libssl-dev libzmq3-dev libsqlite3-dev

FROM rust:1.61.0-slim-buster as builder20
ARG BUILDER_DIR=/srv/rgb

RUN apt-get update \
    && apt-get -y install --no-install-recommends \
        wget build-essential cmake git pkg-config \
        libpq-dev libssl-dev libzmq3-dev libsqlite3-dev

WORKDIR $BUILDER_DIR
RUN cargo install rgb20 --version "=0.8.0-rc.2" \
        --locked --all-features --root "${BUILDER_DIR}"

FROM rust:1.61.0-slim-buster as builder
ARG SOURCE_CODE=https://github.com/crisdut/rgb-node.git
ARG BUILDER_SOURCE=/opt/src/rgb
ARG BUILDER_DIR=/srv/rgb
ARG VERSION=d36e4ad

RUN apt-get update \
    && apt-get -y install --no-install-recommends \
        wget build-essential cmake git pkg-config \
        libpq-dev libssl-dev libzmq3-dev libsqlite3-dev

WORKDIR $BUILDER_DIR
WORKDIR $BUILDER_SOURCE
RUN git clone $SOURCE_CODE $BUILDER_SOURCE
RUN git checkout $VERSION
RUN cargo install --locked --all-features --path . --root ${BUILDER_DIR}

FROM rust:1.61.0-slim-buster as runtime
ARG BUILDER_DIR=/srv/rgb
ARG BIN_DIR=/usr/local/bin
ARG DATA_DIR=/var/lib/rgb
ARG USER=rgbd

RUN adduser --home "${DATA_DIR}" --shell /bin/bash --disabled-login \
        --gecos "${USER} user" ${USER}

COPY --from=builderstd --chown=${USER}:${USER} \
     "${BUILDER_DIR}/bin/" "${BIN_DIR}/"

COPY --from=builder20 --chown=${USER}:${USER} \
     "${BUILDER_DIR}/bin/" "${BIN_DIR}/"

COPY --from=builder --chown=${USER}:${USER} \
     "${BUILDER_DIR}/bin/" "${BIN_DIR}/"

RUN apt-get update -y \
    && apt-get install -y \
       libzmq3-dev \
       iputils-ping \
       libsqlite3-0 \
       libssl1.1 \
       telnetd \
       netcat \
#     && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR "${BIN_DIR}"
USER ${USER}

VOLUME "$DATA_DIR"

EXPOSE 63963

ENTRYPOINT ["rgbd"]

CMD ["-vvvv", "--bin-dir", "/usr/local/bin", "--data-dir", "/var/lib/rgb"]