# docker-rspamd
Dockerfile to run [rspamd](https://rspamd.com/) as a docker container, worker-proxy is used instead of worker-normal as it spawns a new worker if there is a crash while processing.

It has two map files which can be edited in the web UI, filename for extensions to reject and whitelist for domains to whitelist.

To generate a password hash for the web interface run container then exec rspamd_pw.sh inside it and copy output into /etc/override.d/worker-controller.inc and rspamadm reload.
This is then retained in the persistent volume if mounted.

It is configured to read the dkim/arc keys from redis, to manually add a key to redis instructions are on the Rspamd website [https://rspamd.com/doc/modules/dkim_signing.html#dkim-keys-in-redis](https://rspamd.com/doc/modules/dkim_signing.html#dkim-keys-in-redis).

Environment Variables

| NAME   | Description                                     | Default           |
| ------ | ----------------------------------------------- | ----------------- | 
| REDIS  | name/container name or IP of the redis server.  | none (No redis)   |
| OLEFY  | name/container name or IP of the Olefy server.  | do not use Olefy  |
| DCCIFD | name/container name or IP of the DCCIFD server. | do not use dccifd |
| CLAMAV | name/container name or IP of the ClamAV server. | do not use ClamAV |

To run connecting to container network without exposing ports (accessible from host network), and docker managed volumes
```
#docker container run --net MYNET --name rspamd --restart=unless-stopped --mount source=rspamd-var,target=/var/lib/rspamd --mount source=rspamd-over,target=/etc/rspamd/override.d -d a16bitsysop/rspamd
```

To run without connecting to container network exposing ports (accessible from host network), and docker managed volumes
```
#docker container run -p 11332:11332 -p 11334:11334 --name rspamd --restart=unless-stopped --mount source=rspamd-var,target=/var/lib/rspamd --mount source=rspamd-over,target=/etc/rspamd/override.d -d a16bitsysop/rspamd
```
