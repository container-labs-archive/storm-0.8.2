FROM ubuntu:trusty

ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64

RUN apt-get update \
 && apt-get install -y openjdk-7-jdk \
 && apt-get install -y supervisor \
 && apt-get install -y zip unzip curl maven \
 && apt-get install -y curl wget make git pkg-config libtool autoconf automake g++ libzmq-dev \
 && echo [supervisord] | tee -a /etc/supervisor/supervisord.conf \
 && echo nodaemon=true | tee -a /etc/supervisor/supervisord.conf \
 && rm -rf /var/lib/apt/lists/*

#################
# install storm #
ENV STORM_HOME /usr/share/storm
ENV STORM_VERSION 0.8.2
ENV STORM_DOWNLOAD_URL http://tune-resources.s3.amazonaws.com/storm-0.8.2.zip

RUN curl -sSL "$STORM_DOWNLOAD_URL" -o storm.zip
RUN unzip storm.zip -d /usr/share
RUN rm storm.zip \
 && groupadd storm \
 && useradd --gid storm --home-dir /home/storm --create-home --shell /bin/bash storm \
 && mkdir /var/log/storm \
 && chown -R storm:storm /var/log/storm \
 && ln -s /usr/share/storm-$STORM_VERSION $STORM_HOME \
 && ln -s $STORM_HOME/bin/storm /usr/bin/storm \
 && ln -s /var/log/storm $STORM_HOME/logs

###############
# install ZMQ #
ADD install_zmq.sh $STORM_HOME/bin/install_zmq.sh
RUN $STORM_HOME/bin/install_zmq.sh

#################################
# add kafka jar for kafka spout #
ADD ./kafka-0.7.2.jar $STORM_HOME/kafka-0.7.2.jar
RUN mvn install:install-file -Dfile=$STORM_HOME/kafka-0.7.2.jar -DgroupId=kafka -DartifactId=kafka -Dversion=0.7.2 -Dpackaging=jar

ADD storm.yaml $STORM_HOME/conf/storm.yaml
ADD cluster.xml $STORM_HOME/logback/cluster.xml
ADD start-storm.sh /usr/bin/start-storm.sh

# nimbus (thrift drpc drpc.invocations)
EXPOSE 6627 3772 3773
# supervisor (slot logviewer)
EXPOSE 6700 8000
# ui
EXPOSE 8080

ENTRYPOINT ["/usr/bin/start-storm.sh"]
CMD []
