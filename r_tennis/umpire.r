source("tennis.r")

Umpire <- R6Class("Umpire",
    inherit = Tennis,
    public = list(
        position = NULL,
        velocity = NULL,
        initialize = function(redis_conn, framerate, verbose = 1){
            super$initialize(redis_conn, framerate, verbose)
            if(verbose>=1) print("I'm the umpire")
        },
        start_game = function(){
            while(!self$r$EXISTS("ball.position")){
                if(self$verbose>=1) print("Waiting for ball")
                Sys.sleep(1)
            }
            while(any(self$get("ball.position")!=c(0.33,0,0))){
                if(self$verbose>=1) print("Waiting ball to be in position")
                Sys.sleep(1)
            }
            while(!self$r$EXISTS("player.1.position")){
                if(self$verbose>=1) print("Waiting for player 1")
                Sys.sleep(1)
            }
            while(!self$r$EXISTS("player.2.position")){
                if(self$verbose>=1) print("Waiting for player 2")
                Sys.sleep(1)
            }
            self$set("playing", "game.status")
            self$set(0, "game.restart")
        },
        watch_game = function(){
            while(1){
                # start <- proc.start()
                self$watch_position()
                # diff <- proc.stop() - stop
                Sys.sleep(abs(1/self$framerate))# - diff))
            }
        },
        watch_position = function(){
            ball_position <- self$get("ball.position")
            if(any(ball_position>1) || any(ball_position<0)){
               self$new_game()
            }
        },
        new_game = function(){
            self$set(1, "game.restart")
            self$start_game()
        }
    )
)

umpire = Umpire$new(
    redis_conn = redux::hiredis(host = "redis"),
    framerate = 300,
    verbose = as.numeric(Sys.getenv("VERBOSE"))
)
umpire$start_game()
umpire$watch_game()