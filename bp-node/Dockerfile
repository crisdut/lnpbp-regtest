FROM rust:1.61.0-slim-buster as builder
ARG BUILDER_DIR=/srv/bp

RUN apt-get update && apt-get install -y build-essential
        
WORKDIR $BUILDER_DIR
RUN cargo install bp_node --version "=0.8.0-alpha.2" \
        --locked --all-features --root "${BUILDER_DIR}"

FROM rust:1.61.0-slim-buster as runtime

ARG BUILDER_DIR=/srv/bp
ARG BIN_DIR=/usr/local/bin
ARG DATA_DIR=/var/lib/bp
ARG USER=bp

RUN adduser --home "${DATA_DIR}" --shell /bin/bash --disabled-login \
        --gecos "${USER} user" ${USER}

USER ${USER}
WORKDIR "${BIN_DIR}"

COPY --from=builder --chown=${USER}:${USER} \
     "${BUILDER_DIR}/bin/" "${BIN_DIR}/"

VOLUME "$DATA_DIR"

EXPOSE 64964 40940

ENTRYPOINT ["bpd"]

CMD ["-vvvv", "--data-dir", "/var/lib/bp"]