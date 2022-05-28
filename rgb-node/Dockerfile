FROM rust:1.61.0-slim-buster as builder
ARG BUILDER_DIR=/srv/rgb

RUN apt-get update \
    && apt-get -y install --no-install-recommends \
        wget build-essential cmake git pkg-config \
        libpq-dev libssl-dev libzmq3-dev libsqlite3-dev

WORKDIR $BUILDER_DIR
RUN cargo install rgb_node --version "=0.7.0" \
        --locked --all-features --root "${BUILDER_DIR}"

FROM rust:1.61.0-slim-buster as runtime

ARG BUILDER_DIR=/srv/rgb
ARG BIN_DIR=/usr/local/bin
ARG DATA_DIR=/var/lib/rgb
ARG USER=rgbd

RUN apt-get update -y \
    && apt-get install -y \
       libzmq3-dev \
       iputils-ping \
       libsqlite3-0 \
       libssl1.1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN adduser --home "${DATA_DIR}" --shell /bin/bash --disabled-login \
        --gecos "${USER} user" ${USER}

COPY --from=builder --chown=${USER}:${USER} \
     "${BUILDER_DIR}/bin/" "${BIN_DIR}/"

WORKDIR "${BIN_DIR}"
USER ${USER}

# COPY ./data/*.psbt ./

VOLUME "$DATA_DIR"

EXPOSE 6666

ENTRYPOINT ["rgbd"]

CMD ["-vvvv", "--bin-dir", "/usr/local/bin", "--data-dir", "/var/lib/rgb"]