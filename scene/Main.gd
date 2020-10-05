extends Node2D

var music_fade_in_timer_max = 2
var music_fade_in_timer = music_fade_in_timer_max

var slow_song = preload("res://music/main_slow.wav")
var medium_song = preload("res://music/main_medium.wav")
var fast_song = preload("res://music/main_fast.wav")
var current_song = slow_song

onready var music = $Music

func _init():
	# Reset global variables
	global.gang_members_remaining = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	music.volume_db = -80
	music.stream = current_song
	music.play()
	

func _process(delta):
	if(music_fade_in_timer > 0):
		music_fade_in_timer -= delta
		music.volume_db = ((music_fade_in_timer / music_fade_in_timer_max) * -80) - 10

func _on_Music_finished():
	music.stream = current_song
	music.play(0)

func _on_Medium_Music_Speedup_area_entered(area):
	if(area.get_parent().get("type") == "Player"):
		current_song = medium_song

func _on_Fast_Music_Speedup_area_entered(area):
	if(area.get_parent().get("type") == "Player"):
		current_song = fast_song
