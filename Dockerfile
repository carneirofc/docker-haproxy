FROM haproxy:2.1.3-alpine
MAINTAINER Claudio Carneiro

RUN set -xe \
    && apk add --no-cache --purge -uU libssl1.1 lua5.3 lua5.3-dev git pcre zlib openssl\
    && apk add --no-cache --virtual .build-deps build-base  wget unzip gcc\
    && cd /tmp \
    && git clone https://github.com/keplerproject/luarocks.git \
    && cd luarocks \
    && sh ./configure \
    && make build install \
    && cd && luarocks install luasocket \
    && apk del --purge .build-deps \
    && rm -rf /var/cache/apk/* /tmp/* /root/.cache/luarocks

ADD ./errors /usr/local/etc/haproxy/errors
ADD ./lib/haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg

STOPSIGNAL SIGUSR1
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
