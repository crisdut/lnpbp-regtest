FROM rust:1.61.0-slim-buster as builder
ARG SOURCE_CODE=https://github.com/crisdut/rgb-node.git
ARG BUILDER_SOURCE=/opt/src/rgb
ARG BUILDER_DIR=/srv/rgb
ARG VERSION=master

RUN apt-get update && apt-get install -y build-essential git

WORKDIR $BUILDER_DIR
RUN cargo install rgb-std --version "=0.8.0" \
        --debug --locked --all-features --root "${BUILDER_DIR}"

RUN cargo install rgb20 --version "=0.8.0-rc.4" \
        --debug --locked --all-features --root "${BUILDER_DIR}"

# RUN cargo install rgb_node --version "=0.8.0" \
#         --locked --all-features --root "${BUILDER_DIR}"

# RUN cargo install rgb-cli --version "=0.8.0" \
#         --locked --all-features --root "${BUILDER_DIR}"
WORKDIR $BUILDER_SOURCE
RUN git clone $SOURCE_CODE $BUILDER_SOURCE
RUN git checkout $VERSION
# TODO: Remove after release v0.8.x or v0.9
RUN cargo install --locked --debug --all-features --path . --root ${BUILDER_DIR}

FROM rust:1.61.0-slim-buster as runtime
ARG BUILDER_DIR=/srv/rgb
ARG BIN_DIR=/usr/local/bin
ARG DATA_DIR=/var/lib/rgb
ARG USER=rgbd

RUN apt-get update -y \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN adduser --home "${DATA_DIR}" --shell /bin/bash --disabled-login \
        --gecos "${USER} user" ${USER}

USER ${USER}
WORKDIR "${BIN_DIR}"

COPY --from=builder --chown=${USER}:${USER} \
     "${BUILDER_DIR}/bin/" "${BIN_DIR}/"

VOLUME "$DATA_DIR"

EXPOSE 63963

ENTRYPOINT ["rgbd"]

CMD ["-vvvv", "--bin-dir", "/usr/local/bin", "--data-dir", "/var/lib/rgb"]