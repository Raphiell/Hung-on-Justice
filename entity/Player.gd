extends KinematicBody2D

#enum states {
#	idle,
#	move,
#	jump,
#	swing,
#	fall,
#	dodge
#}
#
#export(states) var state = states.idle

# Movement
var movement_vector : Vector2 = Vector2.ZERO
export(float) var max_movement_speed = 300
var movement_speed : float = 200
export(float) var regular_decel_weight = 0.2
var deceleration_weight : float = regular_decel_weight
export(float) var acceleration = 10
var lateral_input : int = 0

# Jumping
export(float) var jump_strength = 450
var jump_buffer : float = 0
export(float) var jump_buffer_max = 0.1 # Seconds you can hit jump before landing and still jump
var jumping = false

# Dodging
export(float) var dodge_speed = 450
var dodge_buffer : float = 0
export(float) var dodge_buffer_max = 0.1 # Seconds you can hit dodge before landing and still dodge
var dodge_roll_timer : float = 0
export(float) var dodge_roll_timer_max = 0.2
var dodge_roll_cooldown : float = 0
export(float) var dodge_roll_cooldown_max = 0.5 # Seconds before you can dodge roll again

# Nodes
onready var character_sprite = $Character
onready var camera = $Camera2D
onready var ui = $UI
onready var cursor = $UI/Cursor

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _physics_process(delta):
	# Mouse
	cursor.transform.origin = get_local_mouse_position()
	
	# Gravity
	movement_vector.y = clamp(movement_vector.y + global.GRAVITY, -9999, global.TERMINAL_VELOCITY)
	
	if(is_on_floor() or is_on_ceiling()):
		movement_vector.y = global.GRAVITY
	
	# Lateral Movement
	if(dodge_roll_timer <= 0):
		lateral_input = 0
		if(Input.is_action_pressed("ui_left")):
			lateral_input = -acceleration
		if(Input.is_action_pressed("ui_right")):
			lateral_input = acceleration
	
	# Jumping
	if(Input.is_action_just_pressed("jump")):
		jump()
	
	# If you buffered a jump
	if(jump_buffer > 0):
		jump_buffer -= delta
		# If you hit the floor at any point during the buffer, jump
		if(is_on_floor()):
			jump()
	
	# Dodge Rolling
	if(Input.is_action_just_pressed("ui_down")):
		if(is_on_floor()):
			dodge()
		else:
			# Buffer
			dodge_buffer = dodge_buffer_max
	
	# If you buffered a dodge
	if(dodge_buffer > 0):
		dodge_buffer -= delta
		# If you hit the floor and your cooldown is over at any point during the buffer, dodge
		if(is_on_floor() and dodge_roll_cooldown <= 0):
			dodge()
	
	# Dodge stopping
	if(dodge_roll_timer > 0):
		dodge_roll_timer -= delta
		if(dodge_roll_timer <= 0 and !jumping):
			movement_speed = max_movement_speed
			character_sprite.frame = 0
	
	# Dodge Cooldown
	if(dodge_roll_cooldown >= 0):
		dodge_roll_cooldown -= delta
	
	# Horizontal motion
	if(lateral_input != 0 or dodge_roll_timer > 0):
		movement_vector.x = clamp(movement_vector.x + lateral_input, -movement_speed, movement_speed)
	else:
		movement_vector.x = lerp(movement_vector.x, 0, deceleration_weight)
	
	move_and_slide(movement_vector, Vector2.UP)
	
	if(jumping and is_on_floor()):
		jumping = false
		movement_speed = max_movement_speed
		character_sprite.frame = 0
		deceleration_weight = regular_decel_weight

func jump():
	# If you are on the floor
	if(is_on_floor()):
		movement_vector.y = -jump_strength
		jumping = true
		character_sprite.frame = 2
		deceleration_weight = 0.05
	else:
		# Start the buffer
		jump_buffer = jump_buffer_max

func dodge():
	if(dodge_roll_cooldown <= 0):
		if(Input.is_action_pressed("ui_left")):
			movement_vector.x = -dodge_speed
		else:
			movement_vector.x = dodge_speed
		movement_speed = dodge_speed
		dodge_roll_timer = dodge_roll_timer_max
		if(!jumping):
			character_sprite.frame = 1
		dodge_roll_cooldown = dodge_roll_cooldown_max
	else:
		dodge_buffer = dodge_buffer_max
