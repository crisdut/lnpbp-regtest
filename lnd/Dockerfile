FROM golang:1.19.2-alpine as builder
ARG SOURCE_CODE=https://github.com/lightningnetwork/lnd
ARG BUILDER_SOURCE=/opt/src/lnd
ARG BUILDER_DIR=/srv/lnd
ARG VERSION=v0.15.5-beta

# Force Go to use the cgo based DNS resolver. This is required to ensure DNS
# queries required to connect to linked containers succeed.
ENV GODEBUG netdns=cgo

# Install dependencies.
RUN apk add --no-cache --update alpine-sdk \
    git \
    make

WORKDIR $BUILDER_DIR
WORKDIR $BUILDER_SOURCE
RUN git clone $SOURCE_CODE $BUILDER_SOURCE
RUN git checkout $VERSION

#  Install/build lnd.
RUN make \
&&  make install tags="signrpc walletrpc chainrpc invoicesrpc peersrpc"

# Start a new, final image to reduce size.
FROM alpine as final
ENV USER=lnd

# Add user
RUN adduser -S ${USER}
VOLUME ["/home/lnd/.lnd"]

# Copy the binaries and entrypoint from the builder image.
COPY --from=builder /go/bin/lncli /bin/
COPY --from=builder /go/bin/lnd /bin/

# Add bash.
RUN apk add --no-cache \
    bash

WORKDIR "/home/lnd/"

# Expose lnd ports (server, rpc).
EXPOSE 9735 10009

# Copy the entrypoint script.
ENTRYPOINT ["lnd"]
CMD ["lnd"]