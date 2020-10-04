extends Node2D

enum states {
	walking,
	shooting
}

var state = states.walking

var type = "Enemy"

# Hit
var hit = false

# Facing
var facing

# Attacking
var attack_cooldown_timer_max = 1
var attack_cooldown_timer = 0
var vision_range = 200
var bullet_scene = preload("res://entity/Bullet.tscn")

# Sprites
var hit_texture = preload("res://texture/badguy_hit.png")

# Death
var health_pickup_scene = preload("res://entity/Health Pickup.tscn")

# Nodes
onready var sprite = $Sprite
onready var rope_point = $"Rope Point"
onready var ray = $RayCast2D
onready var anim = $AnimationPlayer

signal kill

func _ready():
	anim.play("walk")

func _process(delta):
	# Face player
	var x_to_player = sign(global.player.global_transform.origin.x - global_transform.origin.x)
	facing = x_to_player if x_to_player != 0 else 1
	sprite.scale.x = facing
	
	if(attack_cooldown_timer > 0):
		attack_cooldown_timer -= delta
	
	if(hit):
		pass
	else:
		# Check if player is in range and not behind scenery
		ray.cast_to = (global.player.global_transform.origin - global_transform.origin).normalized() * vision_range
		ray.force_raycast_update()
		if(ray.get_collider() and ray.get_collider().get("type") == "Player"):
			if(attack_cooldown_timer <= 0):
				shoot()
				attack_cooldown_timer = attack_cooldown_timer_max

func shoot():
	var bullet = bullet_scene.instance()
	bullet.movement_vector = (global.player.global_transform.origin - global_transform.origin).normalized()
	get_tree().root.add_child(bullet)
	bullet.global_transform.origin = global_transform.origin

func _on_Shooter_kill():
	var hit = true
	sprite.texture = hit_texture
	var blood_particles = global.blood_particles.instance()
	blood_particles.direction.x = facing
	blood_particles.emitting = true
	get_tree().root.add_child(blood_particles)
	blood_particles.global_transform.origin = rope_point.global_transform.origin
	
	# 1 in 3 chance
	if(1 == 1):#randi() % 2 == 0):
		var health_pickup = health_pickup_scene.instance()
		get_tree().root.add_child(health_pickup)
		health_pickup.global_transform.origin = global_transform.origin
	
	queue_free()
