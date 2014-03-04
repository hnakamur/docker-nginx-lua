FROM tianon/centos:6.5
MAINTAINER Hiroaki Nakamura <hnakamur@gmail.com>

RUN yum update -y && \
    rpm --import http://nginx.org/keys/nginx_signing.key && \
    yum install -y http://nginx.org/packages/centos/6/noarch/RPMS/nginx-release-centos-6-0.el6.ngx.noarch.rpm && \
    yum install -y nginx

EXPOSE 80
ENTRYPOINT ["/usr/sbin/nginx", "-g", "daemon off;"]
