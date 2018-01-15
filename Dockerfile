FROM registry.iop.com:5000/os/centos:7.3.1611
MAINTAINER = DamonWang <wangdk@inspur.com>

EXPOSE 5000 35357
ENV KEYSTONE_VERSION stable/ocata
ENV KEYSTONE_ADMIN_PASSWORD 123456a?
ENV KEYSTONE_DB_ROOT_PASSWD 123456a?
ENV KEYSTONE_DB_PASSWD 123456a?
USER root
WORKDIR /root/
RUN rm -rf /etc/yum.repos.d/*
COPY files/yum.repos.d /etc/yum.repos.d/
# install keystone and mysql
RUN yum clean all; \
    yum makecache;\
    yum install -y openssh-server openstack-keystone mysql dos2unix net-tools python-keystoneclient python-openstackclient  openstack-utils httpd mod_wsgi; \
    yum clean all

LABEL version="$KEYSTONE_VERSION"
LABEL description="Openstack Keystone Docker Image Supporting HTTP/HTTPS"


COPY files/etc/keystone.conf /etc/keystone/keystone.conf
COPY files/keystone.sql /root/keystone.sql
COPY files/project.sql /root/project.sql
COPY files/bootstrap.sh /usr/local/bin/bootstrap.sh
COPY files/wsgi-keystone.conf /etc/httpd/conf.d/
RUN chmod 750 /usr/local/bin/bootstrap.sh

CMD ["/usr/local/bin/bootstrap.sh"]
