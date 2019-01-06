FROM node

RUN \
  npm -g install \
#    socket.io@1.7.4 \
    socket.io@2.1.1 \
    express@4.16.4 \
    redis@2.8.0

ADD \
  websocket-tennis /websocket-tennis

WORKDIR websocket-tennis

CMD node app.js
