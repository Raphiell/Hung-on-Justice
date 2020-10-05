extends Node

const GRAVITY = 20
const TERMINAL_VELOCITY = 400

# Groups
const respawn_group = "Respawn"
const audio_player_group = "Audio Player"

var gang_members_remaining = 0

var player

# Particles
var blood_particles = preload("res://entity/Blood Particles.tscn")

func _input(event):
	if(Input.is_action_just_pressed("exit")):
		get_tree().quit()

func _process(delta):
	for audio_player in get_tree().get_nodes_in_group(audio_player_group):
		if(!audio_player.playing):
			audio_player.queue_free()

func play_sound(stream : AudioStream, volume : int = 0, pitch_range : float = 0.2):
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = stream
	audio_player.pitch_scale = rand_range(1 - pitch_range, 1 + pitch_range)
	audio_player.volume_db = volume
	audio_player.add_to_group(global.audio_player_group)
	get_tree().root.add_child(audio_player)
	audio_player.play()
