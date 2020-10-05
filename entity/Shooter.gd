extends KinematicBody2D

enum states {
	walking,
	aiming,
	shooting
}

export(bool) var gang_member = true

var state = states.walking

var type = "Enemy"

# Grab
var is_grabbed : bool = false

# Facing
var facing = -1

# Attacking
var attack_cooldown_timer_max = 0.5
var attack_cooldown_timer = 0
var vision_range = 200
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
export(float) var footstep_timer_max = 0.55
var footstep_timer : float = 0.1
var footstep_sound = preload("res://sound/player_footstep.wav")

# Death
var health_pickup_scene = preload("res://entity/Health Pickup.tscn")
var death_launch_speed : float = 50
var shooter_corpse_scene = preload("res://entity/Shooter Corpse.tscn")
export(bool) var always_drop_health = false
var death_sound = preload("res://sound/enemy_hit.wav")

# Nodes
onready var sprite = $Sprite
onready var rope_point = $"Rope Point"
onready var ray = $RayCast2D
onready var anim = $AnimationPlayer
onready var shoot_point = $"Shoot Point"
onready var hitbox = $Hitbox
onready var audio = $AudioStreamPlayer

signal kill

func _ready():
	if(gang_member):
		global.gang_members_remaining += 1

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
			movement_vector.x = (randi() % 3) - 1
			if(movement_vector.x == 0):
				movement_vector.x += 1
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
			
			if(footstep_timer >= 0):
				footstep_timer -= delta
				if(footstep_timer <= 0):
					footstep_timer = footstep_timer_max
					var distance_to_player = global_transform.origin.distance_to(global.player.global_transform.origin)
					var footstep_volume
					if(distance_to_player > 250):
						footstep_volume = -80
					elif(distance_to_player > 150):
						footstep_volume = -45
					elif(distance_to_player > 125):
						footstep_volume = -40
					elif(distance_to_player > 100):
						footstep_volume = -35
					elif(distance_to_player > 75):
						footstep_volume = -30
					elif(distance_to_player > 50):
						footstep_volume = -25
					elif(distance_to_player > 30):
						footstep_volume = -20
					else:
						footstep_volume = -15
					global.play_sound(footstep_sound, footstep_volume)
		
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
	audio.play(0)

func _on_Shooter_kill(launch_vector : Vector2):
	var blood_particles = global.blood_particles.instance()
	blood_particles.direction.x = facing
	blood_particles.emitting = true
	get_tree().root.add_child(blood_particles)
	blood_particles.global_transform.origin = rope_point.global_transform.origin
	
	# 1 in 4 chance
	if(randi() % 3 == 0 or always_drop_health):
		var health_pickup = health_pickup_scene.instance()
		get_tree().root.add_child(health_pickup)
		health_pickup.global_transform.origin = global_transform.origin
	
	var corpse = shooter_corpse_scene.instance()
	get_tree().root.add_child(corpse)
	corpse.launch_vector = launch_vector * 0.5
	corpse.facing = facing
	corpse.global_transform.origin = global_transform.origin
	
	global.play_sound(death_sound)
	global.gang_members_remaining -= 1
	queue_free()

func _on_AnimationPlayer_animation_finished(anim_name):
	if(anim_name == "shoot" and state == states.shooting):
		state = states.aiming

func _on_Hitbox_area_entered(area):
	if(area.get("type") == "Enemy Bouncer"):
		movement_vector.x *= -1
