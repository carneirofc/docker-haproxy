FROM alpine:3.11.5
MAINTAINER Claudio Carneiro

ENV HAPROXY_MAJOR 2.1
ENV HAPROXY_VERSION 2.1.3

RUN set -xe \
    && apk add --no-cache --purge -uU libssl1.1 lua5.3 lua5.3-dev git pcre zlib\
    && apk add --no-cache --virtual .build-deps build-base unzip \
    && cd /tmp \
    && git clone https://github.com/keplerproject/luarocks.git \
    && cd luarocks \
    && sh ./configure \
    && make build install \
    && cd \
    && apk del --purge .build-deps \
    && rm -rf /var/cache/apk/* /tmp/* /root/.cache/luarocks

RUN buildDeps='curl gcc libc-dev zlib-dev linux-headers pcre-dev openssl-dev make tar' \
    && set -x \
    && apk add --no-cache --purge -uU $buildDeps \
    && curl -SL "http://www.haproxy.org/download/${HAPROXY_MAJOR}/src/haproxy-${HAPROXY_VERSION}.tar.gz" -o haproxy.tar.gz \
    && mkdir -p /usr/src/haproxy \
    && tar -xzf haproxy.tar.gz -C /usr/src/haproxy --strip-components=1 \
    && rm haproxy.tar.gz \
    && make -C /usr/src/haproxy \
    TARGET=linux-glibc\
    USE_LUA=1 \
        LUA_LIB=/usr/lua5.3/lib \
        LUA_INC=/usr/lua5.3/include \
    USE_PCRE=1 \
    USE_OPENSSL=1 \
    USE_ZLIB=1 \
    USE_TFO=1 \
    USE_LIBCRYPT=1 \
    USE_THREAD=1 \
        LDFLAGS=-ldl \
        all \
        install-bin \
    && mkdir -p /usr/local/etc/haproxy \
    && cp -R /usr/src/haproxy/examples/errorfiles /usr/local/etc/haproxy/errors \
    && rm -rf /usr/src/haproxy \
    && apk del $buildDeps

ADD ./errors /etc/haproxy/errors
ADD ./lib/haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
ADD ./lib/acme-http01-webroot.lua /etc/haproxy/acme-http01-webroot.lua
COPY ./lib/entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg", "-p", "/run/haproxy.pid"]
