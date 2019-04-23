FROM ubuntu:latest

RUN apt-get update; \
    apt-get -y install fortune

ADD fortuneloop.sh /bin/fortuneloop.sh

RUN chmod +x /bin/fortuneloop.sh

# Square brackets execute the script in exec mode (rather than running it from a shell) See eBook page 304
ENTRYPOINT ["/bin/fortuneloop.sh"]

CMD ["10"]
