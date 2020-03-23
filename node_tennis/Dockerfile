FROM node

RUN \
  npm -g install \
    socket.io@2.1.1 \
    express@4.16.4 \
    redis@2.8.0

RUN \
  mkdir -p /app/node_tennis

ADD \
  websocket-tennis /app/node_tennis/websocket-tennis

WORKDIR /app/node_tennis/websocket-tennis

CMD node app.js
