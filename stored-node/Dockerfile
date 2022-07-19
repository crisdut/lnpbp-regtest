FROM rust:1.61.0-slim-buster as builder
ARG BUILDER_DIR=/srv/store

RUN apt-get update && apt-get install -y build-essential

WORKDIR $BUILDER_DIR
RUN cargo install store_daemon --version "=0.8.0" \
        --locked --all-features --root "${BUILDER_DIR}"

WORKDIR $BUILDER_DIR
RUN cargo install store-cli --version "=0.8.0" \
        --locked --all-features --root "${BUILDER_DIR}"        

FROM rust:1.61.0-slim-buster as runtime

ARG BUILDER_DIR=/srv/store
ARG BIN_DIR=/usr/local/bin
ARG DATA_DIR=/var/lib/store
ARG USER=store

RUN apt-get update -y \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN adduser --home "${DATA_DIR}" --shell /bin/bash --disabled-login \
        --gecos "${USER} user" ${USER}

USER ${USER}
WORKDIR "${BIN_DIR}"

COPY --from=builder --chown=${USER}:${USER} \
     "${BUILDER_DIR}/bin/" "${BIN_DIR}/"

VOLUME "$DATA_DIR"

EXPOSE 60960 64964

ENTRYPOINT ["stored"]

CMD ["-vvvv", "--data-dir", "/var/lib/store"]