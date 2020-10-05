extends KinematicBody2D

enum states {
	walking,
	aiming,
	shooting
}

var state = states.walking

var type = "Enemy"

# Grab
var is_grabbed : bool = false

# Facing
var facing = 1

# Attacking
var attack_cooldown_timer_max = 0.5
var attack_cooldown_timer = 0
var vision_range = 150
var bullet_scene = preload("res://entity/Bullet.tscn")

# Animation
export(float) var shoot_animation_timer_max = 0.5
var shoot_animation_timer = 0
var walk_texture = preload("res://texture/enemy/enemy_walk.png")
var shoot_texture = preload("res://texture/enemy/enemy_shoot.png")

# Moving
var movement_vector : Vector2 = Vector2(-1, 0)
var movement_speed : float = 35
export(bool) var moves = true

# Death
var health_pickup_scene = preload("res://entity/Health Pickup.tscn")
var death_launch_speed : float = 50
var shooter_corpse_scene = preload("res://entity/Shooter Corpse.tscn")

# Nodes
onready var sprite = $Sprite
onready var rope_point = $"Rope Point"
onready var ray = $RayCast2D
onready var anim = $AnimationPlayer
onready var shoot_point = $"Shoot Point"
onready var hitbox = $Hitbox

signal kill

func _ready():
	pass

func _process(delta):
	if(state == states.aiming):
		sprite.texture = shoot_texture
		sprite.position.x = 12 * facing
		anim.stop()
		sprite.hframes = 3
		sprite.frame = 0
		# Face player
		var x_to_player = sign(global.player.global_transform.origin.x - global_transform.origin.x)
		facing = x_to_player
		
		if(attack_cooldown_timer > 0):
			attack_cooldown_timer -= delta
		
		# Check if player is in range and not behind scenery
		ray.cast_to = (global.player.global_transform.origin - global_transform.origin).normalized() * vision_range
		ray.force_raycast_update()
		if(ray.get_collider() and ray.get_collider().get("type") == "Player"):
			if(attack_cooldown_timer <= 0):
				state = states.shooting
				shoot_animation_timer = shoot_animation_timer_max
		else:
			state = states.walking
			movement_vector.x = (randi() % 2) - 1
	elif(state == states.walking):
		if(moves):
			anim.play("walk")
			sprite.hframes = 4
			sprite.texture = walk_texture
			sprite.position.x = 0
			facing = sign(movement_vector.x)
			if(!is_on_floor()):
				movement_vector.y += global.GRAVITY
			else:
				movement_vector.y = 0
		
			move_and_slide(Vector2(movement_vector.x * movement_speed, movement_vector.y), Vector2.UP)
		else:
			anim.play("aim")
			sprite.hframes = 3
			sprite.texture = shoot_texture
			sprite.position.x = 12 * facing
		ray.cast_to = (global.player.global_transform.origin - global_transform.origin).normalized() * vision_range
		ray.force_raycast_update()
		if(ray.get_collider() and ray.get_collider().get("type") == "Player"):
			state = states.aiming
	elif(state == states.shooting and !is_grabbed):
		var x_to_player = sign(global.player.global_transform.origin.x - global_transform.origin.x)
		facing = x_to_player
		anim.play("shoot")
		sprite.hframes = 3
		sprite.texture = shoot_texture
		sprite.position.x = 12 * facing
		if(shoot_animation_timer > 0):
			shoot_animation_timer -= delta
			if(shoot_animation_timer <= 0):
				shoot()
				attack_cooldown_timer = attack_cooldown_timer_max
	sprite.scale.x = facing if facing != 0 else 1

func shoot():
	var bullet = bullet_scene.instance()
	bullet.movement_vector = (global.player.global_transform.origin - global_transform.origin).normalized()
	get_tree().root.add_child(bullet)
	var shooting_origin = shoot_point.transform.origin
	shooting_origin.x *= facing
	bullet.global_transform.origin = global_transform.origin + shooting_origin

func _on_Shooter_kill(launch_vector : Vector2):
	var blood_particles = global.blood_particles.instance()
	blood_particles.direction.x = facing
	blood_particles.emitting = true
	get_tree().root.add_child(blood_particles)
	blood_particles.global_transform.origin = rope_point.global_transform.origin
	
	# 1 in 3 chance
	if(randi() % 2 == 0):
		var health_pickup = health_pickup_scene.instance()
		get_tree().root.add_child(health_pickup)
		health_pickup.global_transform.origin = global_transform.origin
	
	var corpse = shooter_corpse_scene.instance()
	get_tree().root.add_child(corpse)
	corpse.launch_vector = launch_vector * 0.5
	corpse.facing = facing
	corpse.global_transform.origin = global_transform.origin
	
	queue_free()

func _on_AnimationPlayer_animation_finished(anim_name):
	if(anim_name == "shoot" and state == states.shooting):
		state = states.aiming

func _on_Hitbox_area_entered(area):
	if(area.get("type") == "Enemy Bouncer"):
		movement_vector.x *= -1
