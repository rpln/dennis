
source("setup.r")

if(whoami == "ball"){
  if(verbose>=1) print("I'm a ball")
  position <- c(0.33, 0, 0)
  velocity <- c(0, 0, 0)
  # acceleration <- c(0, 0, -0.01)
  set(position)
  set(velocity)
  while(1){
    velocity <- get(velocity)
    # velocity <- velocity + acceleration
    # if(position[3] < 0){
    #   velocity[3] <- -velocity[3]
    # }
    # set(velocity)
    position = position + velocity
    position[3] <- 0.5-abs(position[2] - 0.5)
    set(position)
    Sys.sleep(sleeptime)
  }
}

if(whoami == "player"){
  if(verbose>=1) print("I'm a player")
  
  position <- list(c(0.33, 0, 0), c(0.66, 1, 0))[[mynumber]]
  myoppositenumber <- 3 - mynumber
  ballnumber <- 1
  velocity <- c(0, 0, 0)
  set(position)
  while(!r$EXISTS("ball.1.position")){
    if(verbose>=1) print("Waiting for ball")
    Sys.sleep(1)
  }

  while(!r$EXISTS(paste0("player.", myoppositenumber, ".position"))){
    if(verbose>=1) print("Waiting for other player")
    Sys.sleep(1)
  }

  if(verbose>=1) print("Starting play")
  
  while(1){
    position = position + velocity
    set(position)
    
    # Can I hit a ball?
    if(
      dist_from_ball <- dist(
        ball_position <- get(name = paste0("ball.", ballnumber, ".position")),
        position
      )<0.1
    ){
      # Hit ball
      velocity <- c(0, 0, 0)
      opposition_position <- get(name = paste0("player.", myoppositenumber, ".position"))

      aim_position <- c(
        c(0.25, 0.75)[(opposition_position[1]<0.5)+1],
        c(1, 0)[position[2]+1],
        0
      )

      # aim_position <- c(
      #   c(0, 1)[(opposition_position[1]<0.5)+1],
      #   c(1, 0)[position[2]+1],
      #   0
      # )

      new_ball_velocity <- c(aim_position[1] - ball_position[1], aim_position[2] - ball_position[2], 0)
      
      #new_ball_velocity[1:2] <- new_ball_velocity[1:2] + rnorm(2)
      new_ball_velocity <- new_ball_velocity/sum(new_ball_velocity^2) # scale to speed=ball_speed
      new_ball_velocity <- ball_speed*new_ball_velocity
      set(new_ball_velocity, name = paste0("ball.", ballnumber, ".velocity"))
      
    }else{
      # Go closer to ball
      velocity <- c(c(-player_speed, player_speed)[(ball_position[1] - position[1] > 0) + 1], 0, 0)
    }
    
    Sys.sleep(sleeptime)
  }
}
