FROM alpine:3.12
LABEL maintainer "Duncan Bellamy <dunk@denkimushi.com>"

ENV dqsver 1.1.0

WORKDIR /tmp
RUN sed -i -e 's/v[[:digit:]]\..*\//edge\//g' /etc/apk/repositories \
&& apk add --no-cache rspamd rspamd-fuzzy rspamd-controller rspamd-proxy drill \
&& mkdir /run/rspamd \
&& wget https://github.com/spamhaus/rspamd-dqs/archive/v${dqsver}.tar.gz \
&& tar -xzf v${dqsver}.tar.gz \
&& cd rspamd-dqs-${dqsver} \
&& mv 2.x /etc/rspamd/rspamd-dqs \
&& cd /tmp && rm -Rf * 

WORKDIR /usr/local/bin
COPY entrypoint.sh ./

WORKDIR /etc/rspamd/local.orig
COPY local.orig ./

WORKDIR /etc/rspamd/local.d
COPY local.conf ./

WORKDIR /etc/rspamd/local.d/maps.orig
COPY --chown=rspamd:rspamd maps/* ./

CMD [ "entrypoint.sh" ]
VOLUME /var/lib/rspamd /etc/rspamd/override.d /etc/rspamd/local.d/maps.d
EXPOSE 11332 11334
