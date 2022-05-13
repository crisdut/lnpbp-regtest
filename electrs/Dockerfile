FROM rust:1.59-alpine3.14 as builder

RUN apk add --no-cache \
  alpine-sdk \
  build-base \
  linux-headers \
  clang \
  cmake \
  snappy-dev \
  git

WORKDIR /usr/local/src/electrs

ARG ELECTRS_VERSION=0.9.0
RUN rustup override set 1.59 \
  && git clone -n https://github.com/romanz/electrs.git . \
  && git checkout v${ELECTRS_VERSION} \
  && RUSTFLAGS="-C target-feature=-crt-static" cargo install --locked --path .

# Build stage for compiled artifacts
FROM alpine:3.12

RUN adduser -S electrs

RUN apk add --no-cache --update libstdc++

COPY --from=builder /usr/local/cargo/bin/electrs /usr/local/bin/electrs
COPY ./config.toml /etc/electrs/config.toml

USER electrs

CMD ["electrs"]