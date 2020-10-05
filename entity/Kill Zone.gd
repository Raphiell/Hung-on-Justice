extends Node2D

var type = "Kill Zone"

export(int) var respawn_id = 0

func _ready():
	visible = false
