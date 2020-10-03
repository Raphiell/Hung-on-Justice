extends Node

const GRAVITY = 20
const TERMINAL_VELOCITY = 400

var player

func _input(event):
	if(Input.is_action_just_pressed("exit")):
		get_tree().quit()
