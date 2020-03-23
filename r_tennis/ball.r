source("tennis.r")

Ball <- R6Class("Ball",
    inherit = Tennis,
    public = list(
        position = NULL,
        velocity = NULL,
        initialize = function(redis_conn, framerate, position, velocity, verbose = 1){
            super$initialize(redis_conn, framerate, verbose)

            if(verbose>=1) print("I'm a ball")

            for(i in list(c(0,0,0.1), c(0,1,0.1), c(1,1,0.1), c(1,0,0.1))){
                self$set(i, "ball.position")
                Sys.sleep(1)
            }
            self$set(self$position <- position, "ball.position")
            self$set(self$velocity <- velocity, "ball.velocity")
        },
        move_step = function(){
            if(self$r$EXISTS("game.restart") && self$get("game.restart")==1){
                self$set(self$position <- c(0.33,0,0), "ball.position")
                self$set(self$velocity <- c(0,0,0), "ball.velocity")
            }else{
                self$velocity = self$get("ball.velocity")
                self$position = self$position + self$velocity
                if(self$position[3] < 0){
                    if(self$velocity[3] < 0){
                        self$velocity[3] <- -self$velocity[3] * 1 # coefficient of restitution
                    }
                    self$position[3] <- 0
                }
                if(sum(abs(self$velocity)) > 0){
                    self$velocity[3] <- self$velocity[3] - 0.02/self$framerate # accelaration due to gravity
                }
                self$set(self$velocity, "ball.velocity")
                self$set(self$position, "ball.position")
            }
        },
        move_continuously = function(){
            while(1){
                # start <- proc.start()
                self$move_step()
                # diff <- proc.stop() - stop
                Sys.sleep(abs(1/self$framerate))# - diff))
            }
        }
    )
)

ball = Ball$new(
    redis_conn = redux::hiredis(host = "redis"),
    framerate = 300,
    verbose = as.numeric(Sys.getenv("VERBOSE")),
    position = c(0.33,0,0),
    velocity = c(0,0,0)
)
ball$move_continuously()