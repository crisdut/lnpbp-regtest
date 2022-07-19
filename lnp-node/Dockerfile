FROM rust:1.61.0-slim-buster as builder
ARG BUILDER_SOURCE=/opt/src/lnp
ARG BUILDER_DIR=/srv/lnp

RUN apt-get update && apt-get install -y build-essential

WORKDIR $BUILDER_DIR
RUN cargo install lnp_node --version "=0.8.0" \
        --locked --all-features --root "${BUILDER_DIR}"

RUN cargo install lnp-cli --version "=0.8.0" \
        --locked --all-features --root "${BUILDER_DIR}"        

# Runtime
FROM rust:1.61.0-slim-buster as runtime

ARG BUILDER_DIR=/srv/lnp
ARG BIN_DIR=/usr/local/bin
ARG DATA_DIR=/var/lib/lnp
ARG USER=lnpd

RUN apt-get update -y \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN adduser --home "${DATA_DIR}" --shell /bin/bash --disabled-login \
            --gecos "${USER} user" ${USER}

COPY --from=builder --chown=${USER}:${USER} \
     "${BUILDER_DIR}/bin/" "${BIN_DIR}"

USER ${USER}
VOLUME ${DATA_DIR}
EXPOSE 9735 62962

WORKDIR ${BIN_DIR}

ENTRYPOINT ["lnpd"]
CMD ["-vvvv", "--data-dir", "/var/lib/lnp"]