FROM dockerfile/ubuntu

RUN \
  apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10 && \
  echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | tee /etc/apt/sources.list.d/mongodb.list && \
  apt-get update && \
  apt-get install -y mongodb-org && \
  mkdir -p /data/db

VOLUME ["/data"]

RUN apt-get -y update
RUN apt-get -y install redis-server supervisor nginx python-dev python-pip git ruby 

RUN mkdir /home/cloudtunes
RUN mkdir /requirements

ADD cloudtunes-server/requirements.txt /requirements.txt
RUN pip install --download=/requirements -r /requirements.txt
RUN pip install --no-index --find-links=/requirements -r /requirements.txt


ADD cloudtunes-server /home/cloudtunes/cloudtunes-server
ADD cloudtunes-webapp /home/cloudtunes/cloudtunes-webapp
RUN pip install /home/cloudtunes/cloudtunes-server
ADD cloudtunes-server/production/supervisor.ini /etc/supervisor/conf.d/cloudtunes.ini

### Launch ###

WORKDIR /home/cloudtunes

# https://docs.docker.com/articles/using_supervisord/
CMD supervisord --nodaemon
