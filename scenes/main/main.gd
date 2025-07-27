# Emerald March
# 07-29-2025
# Brian Morris

extends Node2D

# Main
# code execution begins here
# gives details about main global scene to GameManager

# ready
# called once start startup
func _ready():
	GameManager.initialize(self)
