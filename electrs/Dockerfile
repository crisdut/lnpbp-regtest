FROM rust:1.61.0-alpine3.14 as builder
ARG BUILDER_DIR=/srv/electrs

RUN apk add --no-cache \
  alpine-sdk \
  build-base \
  linux-headers \
  clang \
  cmake \
  snappy-dev 

WORKDIR $BUILDER_DIR

ARG ELECTRS_VERSION=0.9.0
RUN rustup override set 1.61 \
  && RUSTFLAGS="-C target-feature=-crt-static" \
  cargo install electrs --version "=0.9.8" --locked --all-features --root "${BUILDER_DIR}"


# Build stage for compiled artifacts
FROM alpine:3.14
ARG BUILDER_DIR=/srv/electrs
ARG BIN_DIR=/usr/local/bin
ARG USER=electrs

RUN adduser -S "${USER}"
RUN apk add --no-cache --update libstdc++

COPY --from=builder --chown=${USER}:${USER} \
     "${BUILDER_DIR}/bin/" "${BIN_DIR}"

WORKDIR ${BIN_DIR}
COPY ./config.toml /etc/electrs/config.toml

USER ${USER}
CMD ["electrs"]