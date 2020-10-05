extends Control

var mouse_on_start = false
var hovered_texture = preload("res://texture/ui/again_button_hovered.png")
var regular_texture = preload("res://texture/ui/again_button.png")

var shoot_sound = preload("res://sound/pew.wav")

onready var anim = $AnimationPlayer

var pressed = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	anim.play("fade_in")

func _process(delta):
	if(Input.is_action_just_pressed("left_click")):
		if(mouse_on_start and !pressed):
			global.play_sound(shoot_sound, 0, 0.0)
			anim.play("fade_out")
			pressed = true
	if(mouse_on_start):
		$Button.texture = hovered_texture
	else:
		$Button.texture = regular_texture

func _on_Button_mouse_entered():
	mouse_on_start = true

func _on_Button_mouse_exited():
	mouse_on_start = false

func _on_AnimationPlayer_animation_finished(anim_name):
	if(anim_name == "fade_out"):
		get_tree().change_scene_to(load("res://scene/Main.tscn"))
		
