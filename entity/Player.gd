extends KinematicBody2D

enum states {
	regular,
	swinging
}

export(states) var state = states.regular

# Movement
var movement_vector : Vector2 = Vector2.ZERO
export(float) var max_movement_speed = 300
var movement_speed : float = 200
export(float) var regular_decel_weight = 0.2
var deceleration_weight : float = regular_decel_weight
export(float) var regular_acceleration = 20
var acceleration = regular_acceleration
var lateral_input : int = 0

# Jumping
export(float) var jump_strength = 450
var jump_buffer : float = 0
export(float) var jump_buffer_max = 0.1 # Seconds you can hit jump before landing and still jump
var jumping = false
var jump_grace_period : float = 0
export(float) var jump_grace_period_max = 0.15 # Seconds you can hit jump after leaving an edge and still jump

# Dodging
export(float) var dodge_speed = 550
var dodge_buffer : float = 0
export(float) var dodge_buffer_max = 0.1 # Seconds you can hit dodge before landing and still dodge
var dodge_roll_timer : float = 0
export(float) var dodge_roll_timer_max = 0.2
var dodge_roll_cooldown : float = 0
export(float) var dodge_roll_cooldown_max = 0.5 # Seconds before you can dodge roll again

# Animation
var facing : int = 1
onready var idle_texture = preload("res://texture/player/hero_standing.png")
onready var run_texture = preload("res://texture/player/hero_running.png")

# Noose
onready var noose_scene = preload("res://entity/Noose.tscn")
var noose_available = true
var swing_point = null
var swing_speed = 600
var swinging = false
var swing_acceleration = 5
var noose = null

# Nodes
onready var character_sprite = $Character
onready var camera = $Camera2D
onready var ui = $UI
onready var cursor = $UI/Cursor
onready var anim = $AnimationPlayer

# Signals
signal swing_point_attached

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	anim.play("idle")
	global.player = self

func _physics_process(delta):
	# Mouse
	cursor.transform.origin = get_local_mouse_position()
	
	# Facing
	facing = sign(movement_vector.x)
	if(facing != 0):
		character_sprite.scale.x = facing
	
	if(state == states.regular):
		regular_state(delta)
	else:
		swing_state(delta)

func regular_state(delta):
	# Gravity
	movement_vector.y = clamp(movement_vector.y + global.GRAVITY, -9999, global.TERMINAL_VELOCITY)
	
	if(is_on_floor()):
		movement_vector.y = 0
		jump_grace_period = jump_grace_period_max
	elif(is_on_ceiling()):
		movement_vector.y = global.GRAVITY
	
	# Lateral Movement
	if(dodge_roll_timer <= 0):
		lateral_input = 0
		if(Input.is_action_pressed("ui_left")):
			lateral_input = -acceleration
		if(Input.is_action_pressed("ui_right")):
			lateral_input = acceleration
	
	# Jumping
	if(jump_grace_period > 0):
		jump_grace_period -= delta
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
		deceleration_weight = regular_decel_weight
	
	if(swinging and is_on_floor()):
		swinging = false
		deceleration_weight = regular_decel_weight
		acceleration = regular_acceleration
		movement_speed = max_movement_speed
	
	if(swinging and is_on_wall()):
		movement_vector.x = 0
	
	# Animation
	if(abs(movement_vector.x) > 50 or lateral_input != 0):
		character_sprite.texture = run_texture
		character_sprite.vframes = 4
		character_sprite.hframes = 3
		character_sprite.position.y = 7
		anim.play("run")
	else:
		character_sprite.texture = idle_texture
		character_sprite.vframes = 2
		character_sprite.hframes = 4
		character_sprite.position.y = 0
		anim.play("idle")
	
	# Noose
	if(Input.is_action_just_pressed("left_click") and noose_available):
		noose = noose_scene.instance()
		noose.movement_vector = (get_global_mouse_position() - global_transform.origin).normalized()
		get_tree().root.add_child(noose)
		noose.global_transform.origin = global_transform.origin
		noose_available = false

func swing_state(delta):
	move_and_slide(movement_vector, Vector2.UP)
	
	if(global_transform.origin.distance_to(swing_point) < 20 or
	   movement_vector.normalized().dot(global_transform.origin.direction_to(swing_point)) < 0.98):
		state = states.regular
		swing_point = null
		if(is_instance_valid(noose)):
			noose.return_noose()

func jump():
	# If you are on the floor
	if(is_on_floor() or jump_grace_period > 0):
		movement_vector.y = -jump_strength
		jumping = true
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

func _on_Player_swing_point_attached(point):
	swing_point = point
	movement_vector = (swing_point - global_transform.origin).normalized() * swing_speed
	state = states.swinging
	swinging = true
	movement_speed = swing_speed
	deceleration_weight = 0.05
	acceleration = swing_acceleration
