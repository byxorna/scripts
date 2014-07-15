FROM centos:centos6
MAINTAINER Gabe Conradi <gummybearx@gmail.com>
ENV PORT 4000
WORKDIR /app

#RUN rpm -ivh http://mirrors.einstein.yu.edu/epel/6/x86_64/epel-release-6-8.noarch.rpm
# ugh. centos is such a shitbox. npm has multilib errors on 6.5 from EPEL, so just freaking build from source. -_-
#RUN yum install -y nodejs git tar gzip
RUN yum install -y git wget tar gzip gcc gcc-c++ automake autoconf libtoolize make
RUN cd /tmp && wget http://nodejs.org/dist/v0.10.29/node-v0.10.29.tar.gz && tar xzf node-v0.10.29.tar.gz && cd node-v0.10.29 && ./configure && make && make install

RUN git clone https://github.com/byxorna/site.git /app
RUN useradd -d /app -u 1000 user
RUN cd /app && npm install

USER 1000
ENTRYPOINT cd /app && npm start
EXPOSE 4000
