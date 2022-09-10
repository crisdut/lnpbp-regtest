FROM rust:1.61.0-slim-buster as builder
ARG BUILDER_DIR=/srv/storm
ARG BUILDER_SOURCE=/opt/src/storm
ARG SOURCE_CODE=https://github.com/crisdut/storm-node.git
ARG VERSION=fix/receive-container

RUN apt-get update && apt-get install -y build-essential git

WORKDIR $BUILDER_DIR
# RUN cargo install storm_node --version "=0.8.0" \
#         --debug --locked --all-features --root "${BUILDER_DIR}"

# WORKDIR $BUILDER_DIR
# RUN cargo install storm-cli --version "=0.8.0" \
#         --debug --locked --all-features --root "${BUILDER_DIR}"

WORKDIR $BUILDER_SOURCE
RUN git clone $SOURCE_CODE $BUILDER_SOURCE
RUN git checkout $VERSION
RUN cargo install --locked --debug --all-features --path . --root ${BUILDER_DIR}

FROM rust:1.61.0-slim-buster as runtime
ARG BUILDER_DIR=/srv/storm
ARG BIN_DIR=/usr/local/bin
ARG DATA_DIR=/var/lib/storm
ARG USER=storm

RUN apt-get update -y \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN adduser --home "${DATA_DIR}" --shell /bin/bash --disabled-login \
        --gecos "${USER} user" ${USER}

USER ${USER}
WORKDIR "${BIN_DIR}"

COPY --from=builder --chown=${USER}:${USER} \
     "${BUILDER_DIR}/bin/" "${BIN_DIR}/"

VOLUME "$DATA_DIR"

EXPOSE 64964 40940

ENTRYPOINT ["stormd"]

CMD ["-vvvv", "--data-dir", "/var/lib/storm"]