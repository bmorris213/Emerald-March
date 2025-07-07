# Rise of the Dragon King
# 07-07-2025
# Brian Morris

extends Node

# Option
# encapsulates a single choice in a menu or dialogue branch

class_name Option

var option_label : Label
var callable : Callable
var temp : bool

# init
# constructor for options
func _init(label : Label = null, function : Callable = _default_function, temporary : bool = false):
	self.option_label = label
	self.callable = function
	self.temp = temporary

# default function
# a callable for options to use as a default
func _default_function():
	pass
