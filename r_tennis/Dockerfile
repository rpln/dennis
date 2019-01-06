from rocker/r-ver:3.5.1

RUN \
  apt-get update
RUN \
  apt-get install -y libhiredis-dev

RUN \
  install2.r redux jsonlite

ADD \
  tennis.r setup.r /

CMD Rscript tennis.r
