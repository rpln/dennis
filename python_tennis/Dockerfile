FROM python

RUN pip install redis numpy

RUN \
  mkdir -p /app/python_tennis

WORKDIR /app/python_tennis

ADD \
  player.py /app/python_tennis