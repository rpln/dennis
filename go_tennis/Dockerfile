FROM golang:1.13-alpine

RUN apk add git

RUN go get github.com/gomodule/redigo/redis

RUN \
  mkdir -p /app/go_tennis

WORKDIR /app/go_tennis

ADD \
  ball.go /app/go_tennis/