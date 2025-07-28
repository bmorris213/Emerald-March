# Emerald March
# 07-29-2025
# Brian Morris

extends Node2D

# Location
# handles a generating and managing a Location Scene

# node references
@onready var temp_menu := $TextureRect

# set up
# builds a location based on its data
func set_up(data : Dictionary = {}):
	temp_menu.set_up(data)

# set active
# toggles scene control of free roam
func set_active(to_active : bool = true):
	temp_menu.set_active(to_active)
