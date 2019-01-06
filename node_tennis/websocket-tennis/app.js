var express = require('express');
var app = express();
var http = require('http').Server(app);
var io = require('socket.io')(http);

var root_path = process.cwd();

app.use(express.static(root_path + '/public'));

app.get('/', function(req, res) {
  res.sendFile(root_path + '/index.html');
});

http.listen(8000, function(){
  console.log('listening on *:8000');
});


var redis = require("redis"),
    client = redis.createClient({host: 'redis'});

client.on("error", function (err) {
    console.log("Error " + err);
});

console.log('connected to redis');

io.on('connection', function(socket) {
  console.log('Client connected');

  ball_position = [0,0,0];
  player_1_position = [0,0,0];
  player_2_position = [0,0,0];
  setInterval(function() {
    client.get('ball.1.position', function(err, reply) {
        if (reply) {
            ball_position = JSON.parse(reply);
		        io.emit('update_ball_position', ball_position);
        }
    });

    client.get('player.1.position', function(err, reply) {
        if (reply) {
            player_1_position = JSON.parse(reply);
		        io.emit('update_player_1_position', player_1_position);
        }
    });

    client.get('player.2.position', function(err, reply) {
        if (reply) {
            player_2_position = JSON.parse(reply);
    		    io.emit('update_player_2_position', player_2_position);
        }
    });

  }, 30);
});
