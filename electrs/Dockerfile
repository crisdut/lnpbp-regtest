FROM debian:bullseye-slim as builder
ENV BUILDER_DIR=/srv/electrs

RUN apt-get update -qqy
RUN apt-get install -qqy librocksdb-dev=6.11.4-3 curl build-essential cargo clang cmake

WORKDIR $BUILDER_DIR
RUN RUSTFLAGS="-C target-feature=-crt-static" \
  cargo install electrs --version "=0.9.8" --locked --all-features --root "${BUILDER_DIR}"

# Build stage for compiled artifacts
FROM debian:bullseye-slim as runtime
ENV BUILDER_DIR=/srv/electrs
ARG DATA_DIR=/var/lib/electrs
ENV BIN_DIR=/usr/local/bin
ARG USER=electrs

RUN apt-get update -qqy
RUN apt-get install -qqy librocksdb-dev=6.11.4-3 curl \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN adduser --home "${DATA_DIR}" --shell /bin/bash --disabled-login \
            --gecos "${USER} user" ${USER}

COPY --from=builder --chown=${USER}:${USER} \
     "${BUILDER_DIR}/bin/" "${BIN_DIR}"

USER ${USER}
WORKDIR ${BIN_DIR}
COPY ./config.toml /etc/electrs/config.toml

ENTRYPOINT ["electrs"]