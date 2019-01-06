(function() {
  $(document).ready(function() {
    var socket = io();
    var canvas = $('#c')[0];
    var context = canvas.getContext('2d');
    var right = true;
    var vertical_direction = 'up';

    context.clearRect(0, 0, canvas.width, canvas.height);

    var ball     = {x: 0, y: 0 , z: 0};
    var player_1 = {x: 0, y: 0 , z: 0};
    var player_2 = {x: 0, y: 0 , z: 0};

    function scale_x(x){
        return x*190 + 96;
    }

    function scale_y(y){
        return y*350 + 70;
    }

    function scale_z(z){
        return z*40+1
    }

    function set_ball_position(x, y, z) {
        ball.x = scale_x(x);
        ball.y = scale_y(y);
        ball.z = scale_z(z)
    }

    function set_player_1_position(x, y, z) {
        player_1.x = scale_x(x);
        player_1.y = scale_y(y);
        player_1.z = 8
    }

    function set_player_2_position(x, y, z) {
        player_2.x = scale_x(x);
        player_2.y = scale_y(y);
        player_2.z = 8
    }

    socket.on('update_ball_position', function(data) {
      set_ball_position(data[0], data[1], data[2]);
    });

    socket.on('update_player_1_position', function(data) {
      set_player_1_position(data[0], data[1], data[2]);
    });

    socket.on('update_player_2_position', function(data) {
      set_player_2_position(data[0], data[1], data[2]);
    });

    window.onload = function () {
        'use strict';
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;

        var drawing = new Image();
        drawing.onload = function () {
              context.drawImage(drawing, 50, 50, 300, 400);
        }
        drawing.src = "tennis_court.png";

        setInterval(function() {
              context.clearRect(0, 0, canvas.width, canvas.height);

              context.drawImage(drawing, 50, 50, 300, 400);

              context.fillStyle = 'yellow';
              context.fillRect(ball.x, ball.y, ball.z, ball.z);
              context.fillStyle = 'blue';
              context.fillRect(player_1.x, player_1.y, player_1.z, player_1.z);
              context.fillStyle = 'red';
              context.fillRect(player_2.x, player_2.y, player_2.z, player_2.z);
        }, 30);
    };

  });
}).call(this);
