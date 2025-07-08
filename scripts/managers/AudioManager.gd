# Emerald March
# 07-03-2025
# Brian Morris

extends Node

# Audio Manager
# from the main scene, handles all audio requests in the game

class_name AudioManager

var _global_player : AudioStreamPlayer

# set global player
# establishes the audio manager's global cue player
func set_global_player(stream_player : AudioStreamPlayer):
	_global_player = stream_player
