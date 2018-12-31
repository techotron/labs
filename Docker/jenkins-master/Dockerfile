FROM jenkins/jenkins:2.150.1

USER root
RUN apt-get update &&\
    apt-get upgrade -y &&\
    apt-get upgrade -y git &&\
    apt-get install -y software-properties-common &&\
    apt-get install -y awscli &&\
    apt-get update &&\
    apt-get clean

RUN echo "jenkins:password" | chpasswd

RUN mkdir /home/jenkins &&\
    mkdir /home/jenkins/.ssh
COPY ./id_rsa /home/jenkins/.ssh/id_rsa
COPY ./id_rsa.pub /home/jenkins/.ssh/id_rsa.pub

ENV JENKINS_OPTS --httpPort=8080 --httpKeepAliveTimeout=60000
