FROM ubuntu:14.04

# Fix environment and locale issues
ENV TERM linux
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV PATH "$PATH:/usr/bin"


### Setup system ###

# Install mongodb from ppa
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10 \
    && echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' \
        | tee /etc/apt/sources.list.d/mongodb.list \
    && apt-get -y update \
    && apt-get -y install mongodb-org \
    && mkdir -p /data/db

# Mongo DB and Redis will store their data in /data; make it a VOLUME.
VOLUME ["/data"]

# Add nodejs repository and install required packages
RUN apt-get -y install curl
RUN curl -sL https://deb.nodesource.com/setup | sudo bash -

# Install system dependencies
RUN apt-get -y update
RUN apt-get -y install redis-server supervisor nginx python-dev python-pip \
               git ruby python-software-properties python g++ make nodejs \
               build-essential ruby-dev

RUN gem install compass
RUN npm install -g brunch


RUN mkdir /home/cloudtunes
WORKDIR /home/cloudtunes


### Set up cloudtunes-server ###

ADD cloudtunes-server/requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

ADD cloudtunes-server /home/cloudtunes/cloudtunes-server
RUN pip install -e ./cloudtunes-server
ADD cloudtunes-server/production/supervisor.ini \
    /etc/supervisor/conf.d/cloudtunes.conf

### Set up cloudtunes-webapp ###

ADD cloudtunes-webapp /home/cloudtunes/cloudtunes-webapp
RUN cd cloudtunes-webapp \
    && npm install \
    && brunch b --env config-dist.coffee


### User ###
RUN groupadd -r cloudtunes -g 433 \
    && useradd -u 431 -r -g cloudtunes -d /home/cloudtunes \
               -s /usr/sbin/nologin -c "Docker image user" cloudtunes \
    && chown -R cloudtunes:cloudtunes /home/cloudtunes

### Config API keys ###

# Use add, so we can make sure that the file gets cached, and we can check if it's changed since the image was built
ADD cloudtunes-server/cloudtunes/settings/local.py /home/cloudtunes/cloudtunes-server/cloudtunes/settings/local.py

### Launch ###

# https://docs.docker.com/articles/using_supervisord/
CMD ["supervisord", "--nodaemon"]

EXPOSE 8000
