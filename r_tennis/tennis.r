
source("setup.r")

if(whoami == "ball"){
  source("ball.r")
}

if(whoami == "player"){
  source("player.r")
}

if(whoami == "umpire"){
  source("umpire.r")
}
