FROM python:3.7-alpine

RUN mkdir /build && \
    mkdir /app

COPY ./requirements.txt /build/requirements.txt

COPY ./app.py /app/app.py

RUN pip install -r /build/requirements.txt

CMD [ "python", "-u", "/app/app.py" ]