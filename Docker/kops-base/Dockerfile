FROM ubuntu

RUN echo "Updating image..." \
    && apt-get update \
    && apt-get -y install openssh-client curl wget

RUN echo "Creating SSH key..." \
    && [ -d ~/.ssh ] || mkdir ~/.ssh \
    && ssh-keygen -t rsa -N 'id_rsa' -f ~/.ssh/id_rsa

RUN echo "Starting installation..." \
    && apt-get install -y python-pip

RUN echo "Installing KOPS binaries..." \
    && wget -O kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64 \
    && chmod +x ./kops \
    && mv ./kops /usr/local/bin/

RUN echo "Installing kubectl..." \
    && wget -O kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
    && chmod +x ./kubectl \
    && mv ./kubectl /usr/local/bin/kubectl

RUN echo "Installing awscli..." \
    && pip install awscli

CMD echo "default"
