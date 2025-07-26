# Emerald March
# 06-30-2025
# Brian Morris

extends Control

# Battle
# handles a generating and managing a Battle Scene

@onready var _battle_menu := $BattleMenu

# set up
# builds the scene based on data about a new battle
func set_up(battle_data : Dictionary):
	print(battle_data)
	_battle_menu.open()

# erase
# unsets built resources
func erase():
	print("Deleting battle...")

# set active
# enables the menu controls
func set_active(to_active : bool = true):
	_battle_menu.set_active(to_active)

# toggle auto battle
# switches between manual control and auto battle
func toggle_auto_battle():
	print("toggle auto battle")
