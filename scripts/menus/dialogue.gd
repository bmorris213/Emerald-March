# Emerald March
# 07-29-2025
# Brian Morris

extends Node

# Dialgue
# encapsulates a line of dialogue spoken by an actor

class_name Dialogue

# line data
var actor_name : String
var text : String
var choices : Dictionary # string : Callable

# init
# constructor
func _init(_name : String = "", _text : String = "", _choices : Dictionary = {}):
	self.actor_name = _name
	self.text = _text
	self.choices = _choices
