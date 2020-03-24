import numpy as np
import redis
from time import sleep
import json
from math import pi, tan
import os

def dist(location_1, location_2):
    return np.sqrt(
        sum(
            map(
                lambda x: (x[0]-x[1])**2, 
                zip(location_1, location_2)
            )
        )
    )

class Tennis:
    def __init__(self, redis_conn, framerate, verbose = 1):
        self.verbose = verbose
        self.r = redis_conn
        self.framerate = framerate

    def set(self, x, what):
        self.r.set(what, json.dumps(x))

    def get(self, what):
        x = self.r.get(what)
        return json.loads(x)

class Player(Tennis):
    def __init__(self, redis_conn, framerate, position, player_number,
                 max_speed, velocity, min_dist_to_hit_ball, verbose = 1):

        super().__init__(redis_conn, framerate, verbose)
        self.position = position
        self.player_number = player_number
        self.velocity = velocity
        self.opposition_player_number = 3 - player_number
        self.max_speed = max_speed
        self.velocity = velocity
        self.min_dist_to_hit_ball = min_dist_to_hit_ball

        self.set(self.position, "player.me.position")

        while not self.r.exists("game.status"):
            sleep(1)

        while self.get("game.status")[0] != "playing":
            print(self.get("game.status"))
            sleep(1)

        if verbose>=1:
            print("Starting play")

    def move_step(self):

        self.position = list(map(sum, zip(self.position, self.velocity)))
        self.set(self.position, "player.me.position")

        self.check_for_restart()

        ball_position = self.get("ball.position")
        dist_from_ball = dist(ball_position[0:2], self.position[0:2])
        if dist_from_ball < self.min_dist_to_hit_ball:
            self.hit_ball(ball_position)
        else:
            self.move_to_ball(ball_position)

    def move_to_ball(self, ball_position):
        position_to_aim_at = [0]*3
        position_to_aim_at = [
            max([0, min([1, ball_position[0]]) ]),
            [
                max([0, min([0.1, ball_position[1]])]),
                min([1, max([0.9, ball_position[1]])])
            ][self.player_number-1],
            0
        ]
        self.velocity = self.velocity_to_move_to_point(
            self.position,
            position_to_aim_at
        )

    def velocity_to_move_to_point(self, current_location, desired_location):
        velocity = [
            [
                -self.max_speed,
                self.max_speed
            ][
                int(desired_location[0] - current_location[0] > 0)
            ],
            0, 
            0
        ]
        return velocity

    def get_aim_position(self):
        opposition_position = self.get("player.opp.position")
        aim_position = opposition_position
        x_locs_to_try = np.random.uniform(size = 5)
        aim_position[0] = x_locs_to_try[np.argmax(abs(x_locs_to_try - opposition_position[0]))]
        return aim_position

    def estimate_ball_velocity_to_hit_aim_position(self, ball_position, aim_position):
        new_ball_velocity = np.array([
            aim_position[0] - ball_position[0],
            aim_position[1] - ball_position[1],
            0
        ])
        new_ball_velocity[0:2] = new_ball_velocity[0:2] + np.random.normal(size = 2, scale = 0.1)
        new_ball_velocity = new_ball_velocity / sum(new_ball_velocity**2)
        new_ball_velocity = 0.002 * new_ball_velocity
        new_ball_velocity[2] = 0.005

        displacement = np.array(aim_position) - np.array(ball_position)
        theta = pi/4
        t = np.sqrt(2*(abs(displacement[1]) - abs(displacement[2])*tan(theta))) / np.sqrt(tan(theta))
        new_ball_velocity2 = (displacement + np.array([0, 0, (t**2)/2])) / t
        return new_ball_velocity2*0.0075

    def hit_ball(self, ball_position):
        self.velocity = [0, 0, 0]
        aim_position = self.get_aim_position()
        new_ball_velocity = self.estimate_ball_velocity_to_hit_aim_position(ball_position, aim_position)
        self.set(new_ball_velocity.tolist(), "ball.velocity")
        self.data = {'time': [], 'ball_positions': {}}

    def move_continuously(self):
        while 1:
            self.move_step()
            sleep(1 / self.framerate)

    def me_what(self, what):
        what = what.replace("player.me", f'player.{self.player_number}')
        what = what.replace("player.opp", f'player.{self.opposition_player_number}')
        return what

    def set(self, x, what):
        super().set(x, self.me_what(what))

    def get(self, what):
        return super().get(self.me_what(what))

    def check_for_restart(self):
        if self.get("game.restart")==1:
            self.__init__(
                redis_conn = redis.Redis(host = "redis"),
                framerate = 300,
                verbose = int(os.getenv('VERBOSE')),
                player_number = player_number,
                max_speed = 0.002,
                position = [
                    [0.33, 0, 0], 
                    [0.66, 1, 0]
                ][
                    player_number + 1
                ],
                velocity = [0, 0, 0],
                min_dist_to_hit_ball = 0.1
            )

if __name__ == "__main__":
    player_number = int(os.getenv('MYNUMBER'))
    player = Player(
        redis_conn = redis.Redis(host = "redis"),
        framerate = 300,
        verbose = int(os.getenv('VERBOSE')),
        player_number = player_number,
        max_speed = 0.01,
        position = [
            [0.33, 0, 0], 
            [0.66, 1, 0]
        ][
            player_number - 1
        ],
        velocity = [0, 0, 0],
        min_dist_to_hit_ball = 0.1
    )
    player.move_continuously()
