extends Node2D

var type = "Enemy"

# Hit
var hit = false

# Facing
var facing

# Sprites
var hit_texture = preload("res://texture/badguy_hit.png")

# Nodes
onready var sprite = $Sprite
onready var rope_point = $"Rope Point"

signal kill

func _process(delta):
	# Face player
	var x_to_player = sign(global.player.global_transform.origin.x - global_transform.origin.x)
	facing = x_to_player if x_to_player != 0 else 1
	sprite.scale.x = facing
	
	#if(hit):
	#	global

func _on_Shooter_kill():
	var hit = true
	sprite.texture = hit_texture
	var blood_particles = global.blood_particles.instance()
	blood_particles.direction.x = facing
	blood_particles.emitting = true
	get_tree().root.add_child(blood_particles)
	blood_particles.global_transform.origin = rope_point.global_transform.origin
	queue_free()
