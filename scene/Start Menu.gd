extends Control

var mouse_on_start = false
var pressed = false
var hovered_texture = preload("res://texture/ui/start_button_hover.png")
var regular_texture = preload("res://texture/ui/start_button.png")

var shoot_sound = preload("res://sound/pew.wav")

onready var music = $AudioStreamPlayer
onready var button = $Button
onready var anim = $AnimationPlayer

func _ready():
	music.play()

func _process(delta):
	if(Input.is_action_just_pressed("left_click")):
		if(mouse_on_start and !pressed):
			anim.play("fade_out")
			global.play_sound(shoot_sound, 0, 0.0)
			pressed = true
	if(mouse_on_start):
		button.texture = hovered_texture
	else:
		button.texture = regular_texture

func _on_Button_mouse_entered():
	mouse_on_start = true

func _on_Button_mouse_exited():
	mouse_on_start = false

func _on_AnimationPlayer_animation_finished(anim_name):
	get_tree().change_scene_to(load("res://scene/Main.tscn"))
