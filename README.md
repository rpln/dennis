# Docker tennis: Dennis

#### The tennis game consists of:
* Environment: An environment that tracks the state of the game
* Camera: Capturing the state of the environment
* Viewer: Allows observing the environment that camera has captured
* Umpire: Structuring the game, undertaking scoring and enforcing rules
* Ball: Behaving as a ball should
* Players: At least two players that aim to win the tennis game

#### Structure of each component:
* Environment
  * Simple an initially empty redis
* Camera
  * Currently implemented with Node Express
    * [node_tennis/websocket-tennis/app.js]
    * Reads and serves via websocket
      * `ball.1.position`, `player.1.position` and `player.2.position`
* Viewer
  * Currently implemented as a HTML canvas element
* Umpire
  * Currently implemented in R. Methods include
    * `start_game()`
    * `watch_game()`
      * `watch_position()`
    * `new_game()`
    * `set()`
    * `get()`
* Ball
  * Currently implemented in R
    * `move_step()`
    * `move_continuously()`
    * `set()`
    * `get()`
* Players
  * Currently implemented in R
    * `PlayerBasic()`
      * `move_step()`
      * `velocity_to_move_to_point()`
      * `hit_ball()`
      * `move_to_ball()`
      * `move_continuously()`
      * `me_what()`
      * `set()`
      * `get()`
    * `Player()`
      * `get_aim_position()`
      * `estimate_ball_velocity_to_hit_aim_position()`
      * `estimate_ball_landing_point()`
    * `check_for_restart()`

#### Improvements planned:
* Weather which may include
  * Wind - that would affect ball trajectories
  * Rain - that would affect player grip
  * Sun - that would affect player accuracy if it glares in a player's face
* Ensure that players communicate with ball, and not the environment (redis) when hitting the ball
* Python player
* Golang ball
* Split R player into basic player and advanced player
* Collect history of games
  * Either by [redis](https://redis.io/topics/persistence) or by camera
* Add proper score tracking
