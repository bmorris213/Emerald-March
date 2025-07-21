# Emerald March
# 07-22-2025
# Brian Morris

extends Node

# Option
# encapsulates a single choice in a menu or dialogue branch

class_name Option

var option_label : Label
var callable : Callable
var temp : bool

@export var executor : NodePath
@export var method_name : String
@export var arguments : Array

# ready
# called once at startup
func _ready():
	if method_name:
		var node
		if executor:
			node = get_node(executor)
		else:
			node = GameManager
		if node and node.has_method(method_name):
			callable = Callable(node, method_name)
	if not callable:
		callable = _default_function

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
