FROM tianon/centos:6.5
MAINTAINER Hiroaki Nakamura <hnakamur@gmail.com>

RUN cp -p /usr/share/zoneinfo/Japan /etc/localtime && \
    yum update -y

# install LuaJIT
RUN yum install -y curl tar make gcc && \
    cd /usr/local/src && \
    curl -O http://luajit.org/download/LuaJIT-2.0.2.tar.gz && \
    tar xf LuaJIT-2.0.2.tar.gz && \
    cd LuaJIT-2.0.2 && \
    make && \
    make PREFIX=/usr/local/luajit install

# install nginx with lua-nginx-module
RUN yum install -y git curl tar bzip2 make gcc-c++ zlib-devel && \
    export LUAJIT_LIB=/usr/local/luajit/lib && \
    export LUAJIT_INC=/usr/local/luajit/include/luajit-2.0 && \
    cd /usr/local/src && \
    git clone git://github.com/simpl/ngx_devel_kit.git && \
    git clone git://github.com/chaoslawful/lua-nginx-module.git && \
    curl -LO http://downloads.sourceforge.net/project/pcre/pcre/8.34/pcre-8.34.tar.bz2 && \
    tar xf pcre-8.34.tar.bz2 && \
    curl -O http://nginx.org/download/nginx-1.4.6.tar.gz && \
    tar xf nginx-1.4.6.tar.gz && \
    cd nginx-1.4.6 && \
    ./configure --prefix=/usr/local/nginx \
      --with-pcre=/usr/local/src/pcre-8.34 \
      --add-module=/usr/local/src/ngx_devel_kit \
      --add-module=/usr/local/src/lua-nginx-module \
      --with-ld-opt="-Wl,-rpath,$LUAJIT_LIB" && \
    make && \
    make install

# install lua-resty-redis
RUN yum install -y git make gcc && \
    cd /usr/local/src && \
    git clone git://github.com/agentzh/lua-resty-redis.git && \
    cd lua-resty-redis && \
    git checkout -b v0.19 v0.19 && \
    install -d /usr/local/lib/lua/resty && \
    install -t /usr/local/lib/lua/resty lib/resty/redis.lua

ADD conf/ /usr/local/nginx/conf/
ADD public_html/ /usr/local/var/www/public_html/
ADD private_html/ /usr/local/var/www/private_html/

EXPOSE 80
CMD ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"]
