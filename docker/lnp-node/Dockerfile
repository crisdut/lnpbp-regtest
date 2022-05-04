# Modified from original at https://github.com/LNP-BP/lnp-node/blob/demo-3/Dockerfile

# MIT License

# Copyright (c) 2020-2022 LNP/BP Standards Association

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

FROM rust:1.59.0-slim-buster as builder

ARG SOURCE_URL=https:\/\/github.com\/LNP-BP\/lnp-node\/archive\/refs\/tags\/demo-3.tar.gz
ARG RELEASE_NAME=demo-3.tar.gz
ARG SRC_DIR=/usr/local/src/lnp
ARG BUILDER_DIR=/srv/lnp

RUN apt-get update -y \
    && apt-get install -y \
        wget \
        cmake \
        build-essential \
        libsqlite3-dev \
        libssl-dev \
        libzmq3-dev \
        pkg-config

WORKDIR "${SRC_DIR}"

RUN wget "${SOURCE_URL}"
RUN tar -xzf *.tar.gz
RUN rm "${RELEASE_NAME}"

WORKDIR "$SRC_DIR/lnp-node-demo-3/"

RUN mkdir -p ${BUILDER_DIR}
RUN cargo install --path . --root ${BUILDER_DIR} --locked --all-features

FROM rust:1.59.0-slim-buster as runtime

ARG BUILDER_DIR=/srv/lnp
ARG BIN_DIR=/usr/local/bin
ARG DATA_DIR=/var/lib/lnp
ARG USER=lnpd

RUN apt-get update -y \
    && apt-get install -y \
        libzmq3-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN adduser --home "${DATA_DIR}" --shell /bin/bash --disabled-login \
        --gecos "${USER} user" ${USER}

COPY --from=builder --chown=${USER}:${USER} \
     "${BUILDER_DIR}/bin/" "${BIN_DIR}"

WORKDIR "${BIN_DIR}"
USER ${USER}

VOLUME "$DATA_DIR"

EXPOSE 9735 62962

ENTRYPOINT ["lnpd"]

CMD ["-vvv", "--data-dir", "/var/lib/lnp"]