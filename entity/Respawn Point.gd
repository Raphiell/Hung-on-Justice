extends Node2D

export(int) var respawn_id = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false
	add_to_group(global.respawn_group)
