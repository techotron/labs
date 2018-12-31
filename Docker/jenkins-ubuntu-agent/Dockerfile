# Borrowed some bits from https://github.com/bibinwilson/jenkins-docker-slave

FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive

USER root
RUN apt-get update &&\
    apt-get upgrade -y &&\
    apt-get upgrade -y git &&\
    apt-get install -y software-properties-common &&\
    apt-get install -y awscli &&\
    apt-get update &&\
    apt-get clean

# Install SSH server
RUN apt-get install -y openssh-server &&\
    sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd &&\
    mkdir -p /var/run/sshd

# Install JDK 7 (latest edition)
RUN apt-get install -y openjdk-8-jdk

# Set password for the jenkins user (you may want to alter this).
RUN adduser --quiet jenkins &&\
    echo "jenkins:password" | chpasswd

RUN mkdir /home/jenkins/.m2 &&\
    mkdir /home/jenkins/.ssh

#COPY ./id_rsa.pub /home/jenkins/.ssh/id_rsa.pub

ADD settings.xml /home/jenkins/.m2/

RUN chown -R jenkins:jenkins /home/jenkins/.m2/

RUN apt-get install -y maven

# Standard SSH port
EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]