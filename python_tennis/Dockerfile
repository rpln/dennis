FROM python:3.8

RUN pip install \
  redis==3.4.1 \
  numpy==1.18.2

RUN \
  mkdir -p /app/python_tennis

WORKDIR /app/python_tennis

ADD \
  player.py /app/python_tennis