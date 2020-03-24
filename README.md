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
* Ball
  * Currently implemented in Go and R (default = Go)
    * `move_step()`
    * `move_continuously()`
* Players
  * Currently implemented in Python and R (default = Python vs. R)
    * `PlayerBasic()`
      * `move_step()`
      * `velocity_to_move_to_point()`
      * `hit_ball()`
      * `move_to_ball()`
      * `move_continuously()`
      * `me_what()`
    * `Player()`
      * `get_aim_position()`
      * `estimate_ball_velocity_to_hit_aim_position()`
      * `estimate_ball_landing_point()`
    * `check_for_restart()`

#### Improvements planned:
* Core application
  * Improve the players, they are very simple at the moment
  * Collect history of games to understand and improve players
    * Either by [redis](https://redis.io/topics/persistence) or by camera
  * Add proper score tracking
  * Ensure that players communicate with ball, and not the environment (redis) when hitting the ball
    * Requires a ball API
* Graphics
  * 3D, either through a pseudo [2dcanvas transformation](https://www.basedesign.com/blog/how-to-render-3d-in-2d-canvas) or actual 3D
  * Graphs/charts displaying latest state and historical stats; e.g. player energy levels, scoring, ...
* Player learning
  * Factors to include to make things interesting
    * Weather which may include
      * Wind - that would affect ball trajectories
      * Rain - that would affect player grip
      * Sun - that would affect player accuracy if it glares in a player's face
    * Biology
      * A player can run faster, but this uses energy
      * Accuracy can be impacted by energy of player, speed of player, distance from ball, speed of ball
  * Things to predict (resulting in features in a model)
    * Is the ball going to land in or out?
    * Where is the ball going to land precisely?
    * Even if the ball is going to land in the court, is it worth wasting the energy to run for it?
* Deployment
  * Use kubernetes to demonstrate scaling (e.g. a healthcheck could fail if a set is lost, then an additional player is spawned to help out)
