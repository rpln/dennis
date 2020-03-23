source("tennis.r")

PlayerBasic <- R6Class("PlayerBasic",
    inherit = Tennis,
    public = list(
        position = NULL,
        player_number = NULL,
        speed = NULL,
        velocity = NULL,
        min_dist_to_hit_ball = NULL,
        opposition_player_number = NULL,
        data = list(
            time = numeric(0),
            ball_positions = list()
        ),
        initialize = function(redis_conn, framerate, position, player_number, 
                              speed, velocity, min_dist_to_hit_ball, verbose = 1){
            super$initialize(redis_conn, framerate, verbose)

            if(verbose>=1) print(paste0("I'm player ", player_number))

            self$player_number = player_number
            self$opposition_player_number = 3 - player_number
            self$speed = speed
            self$velocity = velocity
            self$min_dist_to_hit_ball = min_dist_to_hit_ball

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
                ) < self$min_dist_to_hit_ball
                # only checking x and y for the moment, not z (height)
            ){
                self$hit_ball(ball_position)
            }else{
                self$move_to_ball(ball_position)
            }
        },
        move_to_ball = function(ball_position){
            position_to_aim_at <- numeric(3)
            position_to_aim_at[1] <- max(c(0,min(c(1,ball_position[1]))))
            position_to_aim_at[2] <- c(
                max(c(0,min(c(0.1,ball_position[2])))),
                min(c(1,max(c(0.9,ball_position[2]))))
            )[self$player_number]
            position_to_aim_at[3] <- 0
            self$velocity <- self$velocity_to_move_to_point(
                self$position, position_to_aim_at
            )
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
            if(self$verbose){
                cat("nbv1:", new_ball_velocity, "\n")
                cat("nbv2:", new_ball_velocity2, "\n")
            }
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
                start <- proc.time()
                self$move_step()
                diff <- proc.time() - start
                Sys.sleep(abs(1/self$framerate - diff['elapsed']))
            }
        },

        # Prefixing redis object names with player numbers
        me_what = function(what){
            what = sub("player.me", paste0("player.", self$player_number), what)
            what = sub("player.opp", paste0("player.", self$opposition_player_number), what)
            return(what)
        },
        set = function(x, what){
            super$set(x, self$me_what(what))
        },
        get = function(what){
            super$get(self$me_what(what))
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


Player <- R6Class("Player",
    inherit = PlayerBasic,
    public = list(
        velocity_to_move_to_point = function(current_location, desired_location){
            translation <- desired_location - current_location
            velocity <- translation
            velocity[3] <- 0
            velocity <- (velocity*self$speed) / sqrt(sum(velocity^2))

            return(velocity)
        },
        estimate_ball_landing_point = function(ball_position){
            self$data$time = c(self$data$time, as.numeric(proc.time()[3]))
            self$data$ball_positions[[length(self$data$ball_positions)+1]] = ball_position
            predicted_position <- self$position[1:2]
            if(length(self$data$time)>4){
                cat("_")
                df <- data.frame(
                    t = self$data$time, 
                    x = sapply(self$data$ball_positions, function(x) x[1]),
                    y = sapply(self$data$ball_positions, function(x) x[2]),
                    z = sapply(self$data$ball_positions, function(x) x[3])
                )
                time_model <- coef(lm(z ~ t + I(t^2), data = df))
                names(time_model) <- c("c", "b", "a")
                time_to_hit_ground <- with(as.list(time_model), max((-b + c(-1, 1)*sqrt(b^2 - 4*a*c))/(2*a)))
                
                position_model <- lm(cbind(x, y) ~ t, data = df)
                new_predicted_position <- as.numeric(
                    predict(position_model, newdata = data.frame(t = time_to_hit_ground))
                )
                if(all(is.finite(new_predicted_position))){
                    cat("_")
                    predicted_position <- new_predicted_position
                }
            }
            return(predicted_position)
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
    velocity = c(0, 0, 0),
    min_dist_to_hit_ball = 0.1
)
player$move_continuously()