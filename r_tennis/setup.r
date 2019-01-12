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
