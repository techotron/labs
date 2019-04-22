FROM ubuntu:18.04

RUN apt-get update \
    && apt-get -y install wget \
    && apt-get -y install default-jre

RUN wget http://mirrors.estointernet.in/apache/kafka/2.2.0/kafka_2.12-2.2.0.tgz

RUN tar -xzf kafka_2.12-2.2.0.tgz

