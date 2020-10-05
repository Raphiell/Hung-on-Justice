extends Node2D

var type = "Noose"

enum states {
	sending,
	returning,
	attached,
	return_with_item
}

var movement_vector : Vector2 = Vector2.ZERO
var movement_speed : float = 15
var return_speed : float = 12
var noose_max_range : float = 200 # How far it can be from the player before returning
var state = states.sending
var grabbed_item = null
var grabbed_enemy = null

var noose_sound = preload("res://sound/noose_attach.wav")

# How long before noose can start hitting stuff
var noose_disabled_timer = 0.0125

# Nodes
onready var rope = $Rope
onready var rope_point = $"Rope Point"

func _physics_process(delta):
	if(is_instance_valid(global.player)):
		if(noose_disabled_timer > 0):
			noose_disabled_timer -= delta
		var noose_distance_from_player = global_transform.origin.distance_to(global.player.global_transform.origin)
		if(state == states.returning):
			movement_vector = (global.player.global_transform.origin - global_transform.origin).normalized()
			global_transform.origin += movement_vector * return_speed
			# Remove noose once it's close enough back to you
			if(noose_distance_from_player <= 10):
				global.player.noose_available = true
				queue_free()
		elif(state == states.sending):
			global_transform.origin += movement_vector * movement_speed
		elif(state == states.attached):
			pass
		elif(state == states.return_with_item):
			if(is_instance_valid(grabbed_item) and grabbed_item.get("type") == "Health Pickup"):
				grabbed_item.global_transform.origin = global_transform.origin
				grabbed_item.collision_mask = 0
				movement_vector = (global.player.global_transform.origin - global_transform.origin).normalized()
				global_transform.origin += movement_vector * return_speed
				# Remove noose once it's close enough back to you
				if(noose_distance_from_player <= 10):
					global.player.noose_available = true
					queue_free()
			else:
				return_noose()
		
		# If noose is too far away, return it to player
		if(noose_distance_from_player > noose_max_range and state != states.return_with_item):
			return_noose()
		
		rope.clear_points()
		rope.add_point(rope_point.transform.origin)
		rope.add_point(global.player.global_transform.origin - transform.origin)
	else:
		queue_free()

func return_noose():
	if(is_instance_valid(grabbed_enemy) and grabbed_enemy.get("type") == "Enemy"):
		grabbed_enemy.is_grabbed = false
		grabbed_enemy = null
	state = states.returning

func _on_Hitbox_area_entered(area):
	if(noose_disabled_timer <= 0):
		if(area.get_parent().get("type") == "Swing Point" and state != states.return_with_item):
			state = states.attached
			global_transform.origin = area.global_transform.origin
			global.player.emit_signal("swing_point_attached", global_transform.origin)
			global.play_sound(noose_sound, -10)
		if(area.get_parent().get("type") == "Enemy" and state != states.return_with_item):
			state = states.attached
			global_transform.origin = area.get_parent().get_node("Rope Point").global_transform.origin
			global.player.emit_signal("enemy_attached", global_transform.origin)
			area.get_parent().is_grabbed = true
			global.play_sound(noose_sound, -10)
			grabbed_enemy = area.get_parent()
		if(area.get_parent().get("type") == "Health Pickup" and area.get_parent().get("pickupable")):
			state = states.return_with_item
			grabbed_item = area.get_parent()
			global.play_sound(noose_sound, -10)
