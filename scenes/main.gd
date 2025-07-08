# Emerald March
# 07-03-2025
# Brian Morris

extends Node2D

# Main
# code execution begins here
# gives details about main global scene to GameManager

# ready
# called once start startup
func _ready():
	GameManager.setup_global_scene(self)
