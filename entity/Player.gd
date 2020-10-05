extends KinematicBody2D

var type = "Player"

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
var original_collision_mask = 0

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

# Dropping through platforms
var drop_through_timer_max = 0.2
var drop_through_timer = 0

# Animation
var facing : int = 1
onready var idle_texture = preload("res://texture/player/hero_standing.png")
onready var charging_idle_texture = preload("res://texture/player/hero_standing_charge.png")
onready var run_texture = preload("res://texture/player/hero_running.png")
onready var charging_run_texture = preload("res://texture/player/hero_running_charge.png")
onready var jump_texture = preload("res://texture/player/hero_jump_noose.png")
onready var charging_jump_texture = preload("res://texture/player/hero_jump_normal.png")
var falling_anim_played = false
var falling = false
export(float) var falling_timer_max = 0.15 # How long you can fall before the falling animation starts
var original_falling_timer_max = 0.15
var quick_falling_timer_max = 0.09
var falling_timer : float = 0
export(Vector2) var hand_location = Vector2.ZERO

# Noose
onready var noose_scene = preload("res://entity/Noose.tscn")
var noose_available = true
var swing_point = null
var slow_swing_speed = 400
var medium_swing_speed = 500
var fast_swing_speed = 600
var low_noose_distance = 100
var medium_noose_distance = 150
var max_noose_distance = 200
var low_noose_speed = 7
var medium_noose_speed = 10
var max_noose_speed = 15
var swing_speed = slow_swing_speed
var swinging = false
var swing_acceleration = 5
var noose = null
export(float) var attach_timer_max = 1
var attach_timer = 0
var weak_noose_texture = preload("res://texture/player/spin_weak.png")
var noose_texture = preload("res://texture/player/spin_normal.png")
var mega_noose_texture = preload("res://texture/player/spin_power.png")

# Attacking
export(float) var kill_buffer_max = 0.2 # Number of seconds you can still kill after hitting the ground
var kill_buffer = 0
export(float) var low_charge_time = 0.5
export(float) var medium_charge_time = 0.8
export(float) var max_charge_time = 1.2
var charged_time : float = 0
var charging : bool = false

# Health
export(int) var max_health = 6
var health = max_health
var heart_indicator_scene = preload("res://entity/Heart Indicator.tscn")

# Nodes
onready var character_sprite = $Character
onready var camera = $Camera2D
onready var ui = $UI
onready var cursor = $UI/Cursor
onready var anim_container = $"Anim Container"
onready var anim = $"Anim Container/AnimationPlayer"
onready var hitbox = $Hitbox
onready var health_control = $"Health Container/Health"
onready var noose_spin = $"Noose Charge Up"
onready var noose_anim = $"Noose Charge Up/AnimationPlayer"
onready var dust = $Dust
onready var dust_anim = $Dust/AnimationPlayer

# Signals
signal swing_point_attached
signal enemy_attached
signal hit

func _ready():
	randomize()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	anim.play("idle")
	noose_anim.play("Noose Charge")
	dust_anim.play("dust_blow")
	global.player = self
	update_health(0)
	original_collision_mask = collision_mask

func _physics_process(delta):
	# Mouse
	cursor.transform.origin = get_local_mouse_position()
	
	# Facing
	facing = sign(movement_vector.x)
	if(facing != 0):
		character_sprite.scale.x = facing
		noose_spin.scale.x = facing
	
	# Put the Noose chargeup sprite in the right spot
	noose_spin.position = Vector2(hand_location.x * facing, hand_location.y)
		
	# Falling
	if(movement_vector.y > 0 and !falling and !is_on_floor()):
		falling_timer -= delta
		if(falling_timer <= 0):
			falling = true
			falling_anim_played = false
	elif(movement_vector.y <= 0):
		falling = false
		falling_timer = falling_timer_max
	elif(is_on_floor()):
		falling = false
		falling_timer_max = original_falling_timer_max
		falling_timer = falling_timer_max
	
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
	
#	# Dodge Rolling
#	if(Input.is_action_just_pressed("ui_down")):
#		if(is_on_floor()):
#			#dodge()
#		else:
#			pass
#			# Buffer
#			#dodge_buffer = dodge_buffer_max
#
#	# If you buffered a dodge
#	if(dodge_buffer > 0):
#		dodge_buffer -= delta
#		# If you hit the floor and your cooldown is over at any point during the buffer, dodge
#		if(is_on_floor() and dodge_roll_cooldown <= 0):
#			dodge()
	
	# Dropping through platforms
	if(Input.is_action_pressed("ui_down")):
		collision_mask = original_collision_mask - 64
		drop_through_timer = drop_through_timer_max
		falling_timer_max = quick_falling_timer_max
		
	
	# Timer for how long to disable one way platforms for player
	if(drop_through_timer > 0):
		drop_through_timer -= delta
		if(drop_through_timer <= 0):
			collision_mask = original_collision_mask
	
#	# Dodge stopping
#	if(dodge_roll_timer > 0):
#		dodge_roll_timer -= delta
#		if(dodge_roll_timer <= 0 and !jumping):
#			movement_speed = max_movement_speed
#
#	# Dodge Cooldown
#	if(dodge_roll_cooldown >= 0):
#		dodge_roll_cooldown -= delta
	
	# Horizontal motion
	if(lateral_input != 0): #or dodge_roll_timer > 0):
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
	if(falling):
		anim.playback_speed = 1
		if(charging or !noose_available):
			character_sprite.texture = charging_jump_texture
		else:
			character_sprite.texture = jump_texture
		character_sprite.vframes = 3
		character_sprite.hframes = 4
		character_sprite.position.y = 0
		if(!falling_anim_played):
			anim.play("jump_down")
			falling_anim_played = true
	elif((abs(movement_vector.x) > 50 or lateral_input != 0) and !jumping and !swinging):
		anim.playback_speed = 1
		if(charging or !noose_available):
			character_sprite.texture = charging_run_texture
		else:
			character_sprite.texture = run_texture
		character_sprite.vframes = 4
		character_sprite.hframes = 3
		character_sprite.position.y = 7
		anim.play("run")
	elif((abs(movement_vector.x) < 50 or lateral_input == 0) and !jumping and !swinging):
		if(charging):
			character_sprite.texture = charging_idle_texture
			character_sprite.vframes = 3
			character_sprite.hframes = 3
			character_sprite.position.y = 0
			anim.play("idle_charging")
			if(charged_time < low_charge_time):
				anim.playback_speed = 0.7
			elif(charged_time < medium_charge_time):
				anim.playback_speed = 1.1
			elif(charged_time < max_charge_time):
				anim.playback_speed = 1.7
			elif(charged_time >= max_charge_time):
				anim.playback_speed = 2.2
		else:
			anim.playback_speed = 1
			character_sprite.texture = idle_texture
			character_sprite.vframes = 2
			character_sprite.hframes = 4
			character_sprite.position.y = 0
			anim.play("idle")
	elif(jumping or swinging):
		anim.playback_speed = 1
		if(charging or !noose_available):
			character_sprite.texture = charging_jump_texture
		else:
			character_sprite.texture = jump_texture
		character_sprite.vframes = 3
		character_sprite.hframes = 4
		character_sprite.position.y = 0
		
	# Noose
	if(Input.is_action_pressed("left_click") and noose_available and !charging):
		charging = true
		charged_time = 0
	else:
		pass
	
	if(Input.is_action_just_released("left_click")):
		charging = false
		if(charged_time < low_charge_time):
			# Don't throw anything
			pass
		else:
			noose = noose_scene.instance()
			noose.movement_vector = (get_global_mouse_position() - global_transform.origin).normalized()
			get_tree().root.add_child(noose)
			noose.global_transform.origin = global_transform.origin
			noose_available = false
			if(charged_time < medium_charge_time):
				noose.noose_max_range = low_noose_distance
				noose.movement_speed = low_noose_speed
				swing_speed = slow_swing_speed
			elif(charged_time < max_charge_time):
				noose.noose_max_range = medium_noose_distance
				noose.movement_speed = medium_noose_speed
				swing_speed = medium_swing_speed
			elif(charged_time >= max_charge_time):
				noose.noose_max_range = max_noose_distance
				noose.movement_speed = max_noose_speed
				swing_speed = fast_swing_speed
		charged_time = 0
		noose_spin.texture = noose_texture

	dust.visible = false
	
	if(charging):
		charged_time += delta
		
	# Noose Animations
	if(charged_time == 0):
		noose_spin.visible = false
		noose_anim.play("Noose Charge")
	else:
		noose_spin.visible = true
	
	if(charged_time > 0 and charged_time < low_charge_time):
		noose_anim.playback_speed = 0.7
		noose_spin.texture = weak_noose_texture
	elif(charged_time < medium_charge_time):
		noose_anim.playback_speed = 1.1
		noose_spin.texture = noose_texture
	elif(charged_time < max_charge_time):
		noose_anim.playback_speed = 1.7
		noose_spin.texture = noose_texture
	elif(charged_time >= max_charge_time):
		noose_anim.playback_speed = 2.2
		noose_spin.texture = mega_noose_texture
		dust.visible = true
	
	
	# Check for enemy kill if buffer is still up
	if(kill_buffer > 0):
		kill_buffer -= delta
		check_for_things(true)
	else:
		check_for_things(false)

func swing_state(delta):
	if(attach_timer > 0):
		attach_timer -= delta
	move_and_slide(movement_vector, Vector2.UP)
	
	if(global_transform.origin.distance_to(swing_point) < 20 or
	   movement_vector.normalized().dot(global_transform.origin.direction_to(swing_point)) < 0.98 or
	   attach_timer <= 0):
		state = states.regular
		kill_buffer = kill_buffer_max
		swing_point = null
		if(is_instance_valid(noose) and noose.get("type") == "Noose"):
			noose.return_noose()
	check_for_things(true)

func check_for_things(able_to_kill : bool):
	# Check for hitting enemies
	var overlapping_areas = hitbox.get_overlapping_areas()
	for area in overlapping_areas:
		if(area.get_parent().get("type") == "Enemy" and able_to_kill):
			area.get_parent().emit_signal("kill", movement_vector)
		elif(area.get_parent().get("type") == "Health Pickup" and area.get_parent().get("pickupable")):
			area.get_parent().emit_signal("pickup")
			update_health(2)
		elif(area.get_parent().get("type") == "Kill Zone"):
			print("Kill me plz")
			for respawn_point in get_tree().get_nodes_in_group(global.respawn_group):
				if(respawn_point.get("respawn_id") == area.get_parent().get("respawn_id")):
					global_transform.origin = respawn_point.global_transform.origin

func jump():
	# If you are on the floor
	if(is_on_floor() or jump_grace_period > 0):
		movement_vector.y = -jump_strength
		jumping = true
		deceleration_weight = 0.05
		anim.play("jump_up")
		falling_timer_max = quick_falling_timer_max
		#falling_anim_played = false
	else:
		# Start the buffer
		jump_buffer = jump_buffer_max

#func dodge():
#	if(dodge_roll_cooldown <= 0):
#		if(Input.is_action_pressed("ui_left")):
#			movement_vector.x = -dodge_speed
#		else:
#			movement_vector.x = dodge_speed
#		movement_speed = dodge_speed
#		dodge_roll_timer = dodge_roll_timer_max
#		if(!jumping):
#			character_sprite.frame = 1
#		dodge_roll_cooldown = dodge_roll_cooldown_max
#	else:
#		dodge_buffer = dodge_buffer_max

func update_health(amount : int):
	health = clamp(health + amount, 0, max_health)
	if(health <= 0):
		get_tree().change_scene_to(load("res://scene/Death Screen.tscn"))
	for node in health_control.get_children():
		node.queue_free()
	
	var health_temp = health
	for i in range(3):
		var heart_indicator = heart_indicator_scene.instance()
		health_control.add_child(heart_indicator)
		heart_indicator.transform.origin.x = 32 * i
		if(health_temp >= 2):
			heart_indicator.frame = 0
		elif(health_temp == 1):
			heart_indicator.frame = 1
		else:
			heart_indicator.frame = 2
		health_temp -= 2

func _on_Player_swing_point_attached(point):
	attach_timer = attach_timer_max
	anim.play("jump_up")
	character_sprite.texture = jump_texture
	character_sprite.vframes = 3
	character_sprite.hframes = 4
	character_sprite.position.y = 0
	#falling_anim_played = false
	falling_timer_max = quick_falling_timer_max
	swing_point = point
	movement_vector = (swing_point - global_transform.origin).normalized() * swing_speed
	state = states.swinging
	swinging = true
	movement_speed = swing_speed
	deceleration_weight = 0.05
	acceleration = swing_acceleration

func _on_Player_enemy_attached(point):
	attach_timer = attach_timer_max
	print("Attacking enemy anim here")
	anim.play("jump_up")
	character_sprite.texture = jump_texture
	character_sprite.vframes = 3
	character_sprite.hframes = 4
	character_sprite.position.y = 0
	falling_timer = 0.05
	#falling_anim_played = false
	swing_point = point
	movement_vector = (swing_point - global_transform.origin).normalized() * swing_speed
	state = states.swinging
	swinging = true
	movement_speed = swing_speed
	deceleration_weight = quick_falling_timer_max
	acceleration = swing_acceleration

func _on_Player_hit():
	update_health(-1)

#func check_for_animation_flip():
#	var current_track = 1
#	var animation = anim.get_animation(anim.current_animation)
#	for i in animation.track_get_key_count(current_track):
#		var key = animation.track_get_key_value(current_track, i)
#		var flipped_key = Vector2(key.x * facing, key.y)
#		animation.track_set_key_value(current_track, i, flipped_key)

func _on_AnimationPlayer_animation_finished(anim_name):
	if(anim_name == "jump_down"):
		anim.play("falling")
