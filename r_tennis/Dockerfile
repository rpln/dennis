FROM rocker/r-ver:3.5.1

RUN \
  apt-get update
RUN \
  apt-get install -y libhiredis-dev

RUN \
  install2.r redux jsonlite R6

ADD \
  ball.r player.r umpire.r