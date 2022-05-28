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

# Modified from original at https://github.com/LNP-BP/lnp-node/blob/demo-3/Dockerfile
FROM rust:1.61.0-slim-buster as builder
# TODO: change after new release (fix regtest)
ARG SOURCE_CODE=https://github.com/crisdut/lnp-node.git
ARG BUILDER_SOURCE=/opt/src/lnp
ARG BUILDER_DIR=/srv/lnp

RUN apt-get update -y \
    && apt-get install -y \
        wget \
        cmake \
        build-essential \
        libsqlite3-dev \
        libssl-dev \
        libzmq3-dev \
        pkg-config \
        git

WORKDIR $BUILDER_DIR
WORKDIR $BUILDER_SOURCE

RUN git clone $SOURCE_CODE $BUILDER_SOURCE
RUN cargo install \
        --locked --all-features --path . --root ${BUILDER_DIR}

FROM rust:1.61.0-slim-buster as runtime

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

VOLUME ${DATA_DIR}

EXPOSE 9735 62962

ENTRYPOINT ["lnpd"]

CMD ["-vvv", "--data-dir", "/var/lib/lnp"]