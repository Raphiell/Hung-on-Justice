extends Node

const GRAVITY = 20
const TERMINAL_VELOCITY = 400

var player

# Particles
var blood_particles = preload("res://entity/Blood Particles.tscn")

func _input(event):
	if(Input.is_action_just_pressed("exit")):
		get_tree().quit()
