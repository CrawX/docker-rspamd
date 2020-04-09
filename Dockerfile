FROM alpine:3.11
LABEL maintainer "Duncan Bellamy <dunk@denkimushi.com>"

RUN sed -i -e 's/v[[:digit:]]\..*\//edge\//g' /etc/apk/repositories && \
apk add --no-cache rspamd rspamd-fuzzy rspamd-controller rspamd-proxy

WORKDIR /usr/local/bin
COPY entrypoint.sh ./

WORKDIR /etc/rspamd/local.orig
COPY local.orig ./

WORKDIR /etc/rspamd/local.d
COPY local.conf ./

WORKDIR /etc/rspamd/local.d/maps.d
COPY --chown=rspamd:rspamd maps/* ./

WORKDIR /etc/rspamd/local.d/maps.orig
COPY --chown=rspamd:rspamd maps/* ./


CMD [ "entrypoint.sh" ]

VOLUME [ "/var/lib/rspamd" "/etc/rspamd/override.d" "/etc/rspamd/local.d/maps.d" ]
EXPOSE 11332 11334
