ARG FIVEM_VERSION=29586-3284e7bf7ac848fcf3ccd51432279fdc3a76245b
ARG DATA_VER=0e7ba538339f7c1c26d0e689aa750a336576cf02

FROM alpine:3.20 AS builder

ARG FIVEM_VERSION
ARG DATA_VER

WORKDIR /output

RUN wget -O- "https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/${FIVEM_VERSION}/fx.tar.xz" \
    | tar xJ --strip-components=1 \
        --exclude alpine/dev --exclude alpine/proc \
        --exclude alpine/run --exclude alpine/sys \
    && mkdir -p /output/opt/cfx-server-data /output/usr/local/share \
    && wget -O- "https://github.com/citizenfx/cfx-server-data/archive/${DATA_VER}.tar.gz" \
    | tar xz --strip-components=1 -C opt/cfx-server-data

ADD server.cfg opt/cfx-server-data/server.cfg
ADD entrypoint.sh usr/bin/entrypoint
RUN chmod +x /output/usr/bin/entrypoint

# ================

FROM scratch

ARG FIVEM_VERSION

LABEL org.opencontainers.image.title="FiveM Dev Server" \
      org.opencontainers.image.description="FiveM server with txAdmin for development" \
      org.opencontainers.image.version=${FIVEM_VERSION}

COPY --from=builder /output/ /
RUN apk add --no-cache tini

WORKDIR /config
EXPOSE 30120 40120

CMD [""]

ENTRYPOINT ["/sbin/tini", "--", "/usr/bin/entrypoint"]
