FROM rocker/r-ver:3.5.1

RUN \
  apt-get update
RUN \
  apt-get install -y libhiredis-dev

RUN \
  install2.r redux jsonlite R6

ADD \
  tennis.r setup.r ball.r player.r /

CMD Rscript tennis.r
