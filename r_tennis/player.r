library(R6)

dist = function(location_1, location_2){
  sqrt(sum((location_1 - location_2)^2))
}

Player <- R6Class("Player",
    public = list(
        verbose = NULL,
        r = NULL,
        framerate = NULL,
        position = NULL,
        player_number = NULL,
        speed = NULL,
        velocity = NULL,
        opposition_player_number = NULL,
        initialize = function(redis_conn, framerate, position, player_number, speed, velocity, verbose = 1){
            self$verbose = verbose
            if(verbose>=1) print(paste0("I'm player ", player_number))

            self$r = redis_conn
            self$framerate = framerate
            self$player_number = player_number
            self$opposition_player_number = 3 - player_number
            self$speed = speed
            self$velocity = velocity

            self$set(self$position <- position, "player.me.position")
            while(!self$r$EXISTS("ball.position")){
                if(self$verbose>=1) print("Waiting for ball")
                Sys.sleep(1)
            }
            while(!self$r$EXISTS(self$me_what("player.opp.position"))){
                if(self$verbose>=1) print("Waiting for other player")
                Sys.sleep(1)
            }
            if(verbose>=1) print("Starting play")
        },
        move_step = function(){
            self$position = self$position + self$velocity
            self$set(self$position, "player.me.position")

            if(
                dist_from_ball <- dist(
                    ball_position <- self$get("ball.position"),
                    self$position
                ) < 0.1
            ){
                # Hit ball
                self$velocity = c(0, 0, 0)
                opposition_position = self$get("player.opp.position")
                aim_position <- c(
                    c(0.25, 0.75)[(opposition_position[1]<0.5)+1],
                    c(1, 0)[self$position[2]+1],
                    0
                )

                new_ball_velocity <- c(aim_position[1] - ball_position[1], aim_position[2] - ball_position[2], 0)
                    
                #new_ball_velocity[1:2] <- new_ball_velocity[1:2] + rnorm(2)
                new_ball_velocity <- new_ball_velocity/sum(new_ball_velocity^2) # scale to speed=ball_speed
                new_ball_velocity <- ball_speed*new_ball_velocity
                self$set(new_ball_velocity, "ball.velocity")
      
            }else{
                # Go closer to ball
                self$velocity <- c(c(-self$speed, self$speed)[(ball_position[1] - self$position[1] > 0) + 1], 0, 0)

            }
        },
        move_continuously = function(){
            while(1){
                # start <- proc.start()
                self$move_step()
                # diff <- proc.stop() - stop
                Sys.sleep(abs(1/framerate))# - diff))
            }
        },
        me_what = function(what){
            what = sub("player.me", paste0("player.", self$player_number), what)
            what = sub("player.opp", paste0("player.", self$opposition_player_number), what)
            return(what)
        },
        set = function(x, what){
            what = self$me_what(what)
            if(self$verbose>=2) cat("set", what, " ", x, "\n")
            self$r$SET(what, jsonlite::toJSON(x))
        },
        get = function(what){
            what = self$me_what(what)
            x <- jsonlite::fromJSON(self$r$GET(what))
            if(self$verbose>=2) cat("get", what, " ", x, "\n")
            return(x)
        }
    )
)

player_number = as.numeric(Sys.getenv("MYNUMBER"))
player = Player$new(
    redis_conn = redux::hiredis(host = "redis"),
    framerate = 300,
    verbose = as.numeric(Sys.getenv("VERBOSE")),
    player_number = player_number,
    speed = 0.002,
    position = list(c(0.33, 0, 0), c(0.66, 1, 0))[[player_number]],
    velocity = c(0, 0, 0)
)
player$move_continuously()