extends Node2D

var type = "Bullet"

var movement_vector : Vector2 = Vector2.ZERO
var movement_speed : int = 5

# Lifetime
var lifetime_timer : float = 2

# Nodes
onready var hitbox = $Hitbox

func _physics_process(delta):
	lifetime_timer -= delta
	if(lifetime_timer <= 0):
		queue_free()
	
	global_transform.origin += movement_vector * movement_speed
	
#	var overlapping_areas = hitbox.get_overlapping_areas()
#	for area in overlapping_areas:
#		if area.get_parent().get("type") == "Player":
#			print("Player Hit")
#			queue_free()

func _on_Hitbox_body_entered(body):
	if(body.get("type") == "Player"):
		body.emit_signal("hit")
	queue_free()
