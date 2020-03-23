FROM rocker/r-ver:3.5.1

RUN \
  apt-get update
RUN \
  apt-get install -y libhiredis-dev

RUN \
  install2.r redux jsonlite R6

RUN \
  mkdir -p /app/r_tennis

WORKDIR /app/r_tennis

ADD \
  ball.r player.r umpire.r /app/r_tennis/