package main

import (
	"encoding/json"
	"log"
	"math"
	"time"

	"github.com/gomodule/redigo/redis"
)

func sumAbs(a *[]float64) (sum float64) {
	for _, v := range *a {
		sum += math.Abs(v)
	}
	return
}

func get(r redis.Conn, what string) []float64 {
	value, _ := r.Do("GET", what)
	var parsed []float64
	if err := json.Unmarshal(value.([]uint8), &parsed); err != nil {
		panic(err)
	}
	return parsed
}

func set(r redis.Conn, what string, x []float64) {
	value, _ := json.Marshal(x)
	r.Do("SET", what, value)
}

func initialize(r redis.Conn) {
	initialPositions := [][]float64{
		{0, 0, 0.1},
		{0, 1, 0.1},
		{1, 1, 0.1},
		{1, 0, 0.1},
	}
	for i := 0; i < 4; i++ {
		set(r, "ball.position", initialPositions[i])
	}

	set(r, "ball.position", []float64{0.33, 0, 0})
	set(r, "ball.velocity", []float64{0, 0, 0})
}

func moveStep(r redis.Conn, framerate int) {
	reset := false
	if gre, _ := r.Do("EXISTS", "game.restart"); gre == int64(1) {
		if grv := get(r, "game.restart")[0]; grv == float64(1) {
			reset = true
		}
	}
	if reset {
		set(r, "ball.position", []float64{0.33, 0, 0})
		set(r, "ball.velocity", []float64{0, 0, 0})
	} else {
		position := get(r, "ball.position")
		velocity := get(r, "ball.velocity")
		for i := range position {
			position[i] = position[i] + velocity[i]
		}
		if position[2] < 0 {
			if velocity[2] < 0 {
				velocity[2] = -velocity[2] * float64(1)
			}
			position[2] = 0
		}
		if x := sumAbs(&velocity); x > 0 {
			velocity[2] = velocity[2] - 0.02/float64(framerate)
		}

		set(r, "ball.position", position)
		set(r, "ball.velocity", velocity)
	}
}

func moveContinuously(r redis.Conn, framerate int) {
	for true {
		moveStep(r, framerate)
		time.Sleep(time.Duration(1000000/framerate) * time.Microsecond)
	}
}

func main() {
	r, err := redis.Dial("tcp", "redis:6379")
	if err != nil {
		log.Fatal(err)
	}
	defer r.Close()

	initialize(r)

	framerate := 300
	moveContinuously(r, framerate)

	if err != nil {
		log.Fatal(err)
	}
}
