FROM rust:1.61.0-slim-buster as builder
ARG BUILDER_DIR=/srv/rgb

RUN apt-get update && apt-get install -y build-essential

WORKDIR $BUILDER_DIR
RUN cargo install rgb-std --version "=0.8.0" \
        --locked --all-features --root "${BUILDER_DIR}"

RUN cargo install rgb20 --version "=0.8.0-rc.3" \
        --locked --all-features --root "${BUILDER_DIR}"

RUN cargo install rgb_node --version "=0.8.0-rc.1" \
        --locked --all-features --root "${BUILDER_DIR}"

RUN cargo install rgb-cli --version "=0.8.0-rc.1" \
        --locked --all-features --root "${BUILDER_DIR}"

FROM rust:1.61.0-slim-buster as runtime
ARG BUILDER_DIR=/srv/rgb
ARG BIN_DIR=/usr/local/bin
ARG DATA_DIR=/var/lib/rgb
ARG USER=rgbd

RUN adduser --home "${DATA_DIR}" --shell /bin/bash --disabled-login \
        --gecos "${USER} user" ${USER}

COPY --from=builder --chown=${USER}:${USER} \
     "${BUILDER_DIR}/bin/" "${BIN_DIR}/"

RUN apt-get update -y \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR "${BIN_DIR}"
USER ${USER}

VOLUME "$DATA_DIR"

EXPOSE 63963

ENTRYPOINT ["rgbd"]

CMD ["-vvvv", "--bin-dir", "/usr/local/bin", "--data-dir", "/var/lib/rgb"]