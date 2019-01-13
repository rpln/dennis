library(R6)

Ball <- R6Class("Ball",
    public = list(
        verbose = NULL,
        r = NULL,
        framerate = NULL,
        position = NULL,
        velocity = NULL,
        initialize = function(redis_conn, framerate, position, velocity, verbose = 1){
            self$verbose = verbose
            if(verbose>=1) print("I'm a ball")

            self$r = redis_conn
            for(i in list(c(0,0,0.1), c(0,1,0.1), c(1,1,0.1), c(1,0,0.1))){
                self$set(i, "ball.position")
                Sys.sleep(1)
            }
            self$set(self$position <- position, "ball.position")
            self$set(self$velocity <- velocity, "ball.velocity")
            self$framerate = framerate
        },
        move_step = function(){
            if(self$r$EXISTS("game.restart") && self$get("game.restart")==1){
                self$set(self$position <- c(0.33,0,0), "ball.position")
                self$set(self$velocity <- c(0,0,0), "ball.velocity")
            }

            self$velocity = self$get("ball.velocity")
            self$position = self$position + self$velocity
            self$position[3] <- 0.5-abs(self$position[2]-0.5) # Not implementing gravity yet
            self$set(self$position, "ball.position")
        },
        move_continuously = function(){
            while(1){
                # start <- proc.start()
                self$move_step()
                # diff <- proc.stop() - stop
                Sys.sleep(abs(1/self$framerate))# - diff))
            }
        },
        set = function(x, what){
            self$r$SET(what, jsonlite::toJSON(x))
            if(self$verbose>=2) cat("set", what, " ", x, "\n")
        },
        get = function(what){
            x <- jsonlite::fromJSON(self$r$GET(what))
            if(self$verbose>=2) cat("get", what, " ", x, "\n")
            return(x)
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