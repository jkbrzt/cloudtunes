FROM dockerfile/ubuntu

#Install mongodb from ppa
RUN \
  apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10 && \
  echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | tee /etc/apt/sources.list.d/mongodb.list && \
  apt-get update && \
  apt-get install -y mongodb-org && \
  mkdir -p /data/db

VOLUME ["/data"]



#Add nodejs repository and install required packages
RUN add-apt-repository ppa:chris-lea/node.js -y
RUN apt-get -y update
RUN apt-get -y install redis-server supervisor nginx python-dev python-pip git ruby python-software-properties python g++ make nodejs build-essential ruby-dev
RUN gem install compass
RUN npm install -g brunch 

RUN mkdir /home/cloudtunes
RUN mkdir /requirements

WORKDIR /home/cloudtunes

ADD cloudtunes-server /home/cloudtunes/cloudtunes-server
ADD cloudtunes-webapp /home/cloudtunes/cloudtunes-webapp
RUN mkdir /home/cloudtunes/cloudtunes-webapp/public

RUN pip install --download=/requirements -r /home/cloudtunes/cloudtunes-server/requirements.txt
RUN pip install --no-index --find-links=/requirements -r /home/cloudtunes/cloudtunes-server/requirements.txt


RUN pip install -e /home/cloudtunes/cloudtunes-server

#fix environment and locale issues
ENV TERM linux
RUN locale-gen en_US.UTF-8  
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8 

RUN cd cloudtunes-webapp && \
    npm install . && \
    /usr/bin/brunch build --production --config=config-dist.coffee && \
    mv build/production/* public/    


ADD cloudtunes-server/production/supervisor.conf /etc/supervisor/conf.d/cloudtunes.conf


RUN groupadd -r cloudtunes -g 433 && \
  useradd -u 431 -r -g cloudtunes -d /home/cloudtunes -s /usr/sbin/nologin -c "Docker image user" cloudtunes && \
  chown -R cloudtunes:cloudtunes /home/cloudtunes

### Launch ###


# https://docs.docker.com/articles/using_supervisord/
RUN /bin/cp /home/cloudtunes/cloudtunes-server/cloudtunes/settings/local.example.py /home/cloudtunes/cloudtunes-server/cloudtunes/settings/local.py
CMD ["supervisord", "--nodaemon"]

EXPOSE 8000
EXPOSE 8001
