FROM debian:bookworm-slim

ARG FIVEM_VERSION=29586-3284e7bf7ac848fcf3ccd51432279fdc3a76245b
ARG DATA_VER=0e7ba538339f7c1c26d0e689aa750a336576cf02

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget xz-utils tini ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

RUN wget -O fx.tar.xz \
      "https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/${FIVEM_VERSION}/fx.tar.xz" \
    && mkdir -p /opt/cfx-server \
    && tar xf fx.tar.xz -C /opt/cfx-server --strip-components=1 \
         --exclude alpine/dev --exclude alpine/proc \
         --exclude alpine/run --exclude alpine/sys \
    && rm fx.tar.xz

RUN mkdir -p /opt/cfx-server-data \
    && wget -O data.tar.gz \
      "https://github.com/citizenfx/cfx-server-data/archive/${DATA_VER}.tar.gz" \
    && tar xzf data.tar.gz -C /opt/cfx-server-data --strip-components=1 \
    && rm data.tar.gz

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY server.cfg /opt/cfx-server-data/server.cfg
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN mkdir -p /config /txData

WORKDIR /config
EXPOSE 30120 40120

ENTRYPOINT ["tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD [""]
