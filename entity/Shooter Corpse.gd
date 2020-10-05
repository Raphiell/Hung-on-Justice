extends KinematicBody2D

var launch_vector : Vector2 = Vector2.ZERO
var facing : int = -1
var max_bounces : int = 2
var bounces = 0
var bleed_timer_max = 3 # How long the shooter will bleed after stopping
var bleed_timer = 0
var original_blood_velocity : float
var blood_slowdown_started : bool = false
var original_particle_position : Vector2 = Vector2.ZERO
var bounce_sound = preload("res://sound/player_footstep.wav")

# Nodes
onready var sprite = $Sprite
onready var particles = $CPUParticles2D

# Called when the node enters the scene tree for the first time.
func _ready():
	original_particle_position = particles.position
	original_blood_velocity = particles.initial_velocity

func _physics_process(delta):
	sprite.scale.x = facing if facing != 0 else 1
	particles.position.x = original_particle_position.x * (facing if facing != 0 else 1)
	if(launch_vector.y < 0):
		sprite.frame = 0
	elif(launch_vector.y > 0 and launch_vector.y < 50):
		sprite.frame = 1
	elif(launch_vector.y > 50):
		sprite.frame = 2
	else:
		sprite.frame = 3

	if(!is_on_floor()):
		launch_vector.y += global.GRAVITY / 2
	else:
		if(bounces < max_bounces):
			bounces += 1
			launch_vector.y *= -0.5
			launch_vector.x *= 0.7
			global.play_sound(bounce_sound, -20)
		else:
			launch_vector = Vector2.ZERO
			if(!blood_slowdown_started):
				blood_slowdown_started = true
				bleed_timer = bleed_timer_max
	
	if(is_on_ceiling()):
		launch_vector.y = global.GRAVITY
	
	if(is_on_wall()):
		launch_vector.x *= -1
	
	move_and_slide(launch_vector, Vector2.UP)
	
	if(bleed_timer > 0):
		bleed_timer -= delta
		particles.initial_velocity = original_blood_velocity * bleed_timer
		if(bleed_timer <= 0):
			particles.emitting = false
