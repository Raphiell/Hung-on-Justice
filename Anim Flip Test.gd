extends Node2D

export(Vector2) var dummy = Vector2.ZERO

func _ready():
	$AnimationPlayer.play("idle")

func _process(delta):
	if(Input.is_action_just_pressed("ui_left")):
		$Sprite.scale.x = -1
	if(Input.is_action_just_pressed("ui_right")):
		$Sprite.scale.x = 1
	$Sprite2.position = Vector2(dummy.x * $Sprite.scale.x, dummy.y)
