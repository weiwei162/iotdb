FROM maven:3.8.4-openjdk-11-slim AS builder

RUN apt-get clean all \
    && apt-get update \
    && apt-get install -y automake bison flex g++ git libboost-all-dev libevent-dev libssl-dev libtool make pkg-config \
    && cd /tmp \
    && curl -Lo thrift.tar.gz https://github.com/apache/thrift/archive/refs/tags/v0.16.0.tar.gz \
    && tar zxf thrift.tar.gz \
    && cd thrift-0.16.0 \
    && ./bootstrap.sh \
    && ./configure \
    && make \
    && make install \
    && rm -rf /tmp/*

COPY . /app

WORKDIR /app

RUN mvn clean package -DskipTests -Dthrift.download-url=http://apache.org/licenses/LICENSE-2.0.txt -Dthrift.exec.absolute.path=/usr/local/bin/thrift

FROM openjdk:11-jre-slim
RUN apt update \
  # procps is for `free` command
  && apt install lsof procps -y \
  && apt autoremove -y \
  && apt purge --auto-remove -y \
  && apt clean -y

COPY --from=builder /app/distribution/target/apache-iotdb-0.12.4-all-bin/apache-iotdb-0.12.4-all-bin /iotdb

# rpc port
EXPOSE 6667
# JMX port
EXPOSE 31999
# sync port
EXPOSE 5555
# monitor port
EXPOSE 8181
VOLUME /iotdb/data
VOLUME /iotdb/logs
ENV PATH="/iotdb/sbin/:/iotdb/tools/:${PATH}"
ENTRYPOINT ["/iotdb/sbin/start-server.sh"]
