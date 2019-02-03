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
            while(!self$r$EXISTS("game.status")){
                Sys.sleep(1)
            }
            while(self$get("game.status")!="playing"){
                Sys.sleep(1)
            }
            if(verbose>=1) print("Starting play")
        },
        move_step = function(){
            self$position = self$position + self$velocity
            self$set(self$position, "player.me.position")

            self$check_for_restart()
            if(
                dist_from_ball <- dist(
                    (ball_position <- self$get("ball.position"))[1:2],
                    self$position[1:2]
                ) < 0.1
                # only checking x and y for the moment, not z (height)
            ){
                self$hit_ball(ball_position)
            }else{
                position_to_aim_at <- ball_position
                position_to_aim_at[1] <- max(c(0,min(c(1,ball_position[1]))))
                position_to_aim_at[2] <- c(
                    max(c(0,min(c(0.1,ball_position[2])))),
                    min(c(1,max(c(0.9,ball_position[2]))))
                )[self$player_number]
                position_to_aim_at[3] <- 0
                self$velocity <- self$velocity_to_move_to_point(
                    self$position, position_to_aim_at
                )


                
            }
        },
        velocity_to_move_to_point = function(current_location, desired_location){
            velocity <- c(
                c(
                    -self$speed, 
                    self$speed
                )[(desired_location[1] - current_location[1] > 0) + 1], 
                0, 
                0
            )

            return(velocity)
        },
        get_aim_position = function(){
                opposition_position = self$get("player.opp.position")
            aim_position <- opposition_position
            x_locs_to_try <- runif(5)
            aim_position[1] <- x_locs_to_try[which.max(abs(x_locs_to_try - opposition_position[1]))]
            return(aim_position)
        },
        estimate_ball_velocity_to_hit_aim_position = function(ball_position, aim_position){
            new_ball_velocity <- c(
                aim_position[1] - ball_position[1], 
                aim_position[2] - ball_position[2], 
                    0
                )

                new_ball_velocity[1:2] <- new_ball_velocity[1:2] + rnorm(2, sd = 0.1)
                new_ball_velocity <- new_ball_velocity/sum(new_ball_velocity^2) # scale to speed=ball_speed
                new_ball_velocity <- 0.002*new_ball_velocity
            new_ball_velocity[3] <- 0.005

            displacement <- aim_position - ball_position
            theta <- pi/4
            t <- sqrt(2*(abs(displacement[2]) - abs(displacement[3])*tan(theta)))/sqrt(tan(theta))
            new_ball_velocity2 <- (displacement + c(0, 0, (t^2)/2)) / t
            # cat("nbv1:", new_ball_velocity, "\n")
            # cat("nbv2:", new_ball_velocity2, "\n")
            return(new_ball_velocity2*0.0075)
        },
        hit_ball = function(ball_position){
            self$velocity = c(0, 0, 0)
            aim_position <- self$get_aim_position()
            new_ball_velocity <- self$estimate_ball_velocity_to_hit_aim_position(ball_position, aim_position)
                self$set(new_ball_velocity, "ball.velocity")
            self$data <- list(
                time = numeric(0),
                ball_positions = list()
            )
        },
        move_continuously = function(){
            while(1){
                # start <- proc.start()
                self$move_step()
                # diff <- proc.stop() - stop
                Sys.sleep(abs(1/self$framerate))# - diff))
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
        },
        check_for_restart = function(){
            if(self$get("game.restart")==1){
                self$initialize(
                    redis_conn = redux::hiredis(host = "redis"),
                    framerate = 300,
                    verbose = as.numeric(Sys.getenv("VERBOSE")),
                    player_number = player_number,
                    speed = 0.002,
                    position = list(c(0.33, 0, 0), c(0.66, 1, 0))[[player_number]],
                    velocity = c(0, 0, 0)
                )
            }
        }
    )
)

player_number = as.numeric(Sys.getenv("MYNUMBER"))
player = Player$new(
    redis_conn = redux::hiredis(host = "redis"),
    framerate = 300,
    verbose = as.numeric(Sys.getenv("VERBOSE")),
    player_number = player_number,
    speed = 0.01,
    position = list(c(0.33, 0, 0), c(0.66, 1, 0))[[player_number]],
    velocity = c(0, 0, 0)
)
player$move_continuously()