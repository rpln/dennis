whoami <- Sys.getenv("WHOAMI")
mynumber <- as.numeric(Sys.getenv("MYNUMBER"))
verbose <- as.numeric(Sys.getenv("VERBOSE"))
if(is.na(verbose)) verbose <- 1

if(verbose>=1) print("Start")

r <- redux::hiredis(host = "redis")

# RUN
framerate <- 300
sleeptime <- 1/framerate
player_speed <- 0.002
ball_speed <- 0.002

if(verbose>=1)  print("While")
if(verbose>=1)  print(whoami)

# Functions

dist = function(location_1, location_2){
  sqrt(sum((location_1 - location_2)^2))
}

set <- function(x, name = paste0(whoami, ".", mynumber, ".", deparse(substitute(x)))){
  r$SET(name, jsonlite::toJSON(x))
  if(verbose>=2) cat("set", name, " ", x, "\n")
}

get <- function(x, name = paste0(whoami, ".", mynumber, ".", deparse(substitute(x)))){
  x <- jsonlite::fromJSON(r$GET(name))
  if(verbose>=2) cat("get", name, " ", x, "\n")
  return(x)
}
