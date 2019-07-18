FROM python:3.7-alpine

RUN mkdir /build && \
    mkdir /app

COPY ./requirements.txt /build/requirements.txt

COPY  ./cert_checker.py /app/cert_checker.py

RUN pip install -r /build/requirements.txt

CMD [ "python", "-u", "/app/cert_checker.py" ]