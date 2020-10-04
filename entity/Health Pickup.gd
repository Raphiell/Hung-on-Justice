extends KinematicBody2D

var type = "Health Pickup"

var rotation_speed : float = 0
var movement_vector : Vector2 = Vector2.UP
var launch_force : float = rand_range(300, 500)
var pickup_timer : float = 0.2 # How many seconds before it can be picked up
var pickupable = false

# Nodes
onready var sprite = $Sprite

# Signals
signal pickup

# Called when the node enters the scene tree for the first time.
func _ready():
	rotation_speed = rand_range(5, 20)
	movement_vector *= launch_force

func _process(delta):
	if(pickup_timer > 0):
		pickup_timer -= delta
		if(pickup_timer <= 0):
			pickupable = true
	
	if(is_on_ceiling()):
		movement_vector.y = global.GRAVITY
	
	if(!is_on_floor()):
		sprite.rotate(deg2rad(rotation_speed))
		movement_vector.y += global.GRAVITY / 2
		move_and_slide(movement_vector, Vector2.UP)

func _on_Health_Pickup_pickup():
	queue_free()
