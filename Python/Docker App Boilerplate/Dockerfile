FROM python:3.7-alpine

RUN mkdir /build && \
    mkdir /app

COPY ./requirements.txt /build && \
     ./cert_checker.py /app

CMD [ "python", "-u", "/app/cert_checker.py" ]