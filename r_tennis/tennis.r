library(R6)

dist = function(location_1, location_2){
  sqrt(sum((location_1 - location_2)^2))
}

Tennis <- R6Class("Tennis",
    public = list(
        verbose = NULL,
        r = NULL,
        framerate = NULL,
        initialize = function(redis_conn, framerate, verbose = 1){
            self$verbose = verbose
            self$r = redis_conn
            self$framerate = framerate
        },

        # setting and getting from redis
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