# Emerald March
# 07-22-2025
# Brian Morris

extends Label

# Option
# encapsulates a single choice in a menu or dialogue branch

class_name Option

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
		# potential node path resolution fix
		for i in arguments.size():
			if arguments[i] is NodePath:
				arguments[i] = _resolve_node_path(arguments[i])
	if not callable:
		callable = _default_function

# init
# constructor for options
func _init(_text : String = "", function : Callable = _default_function, temporary : bool = false):
	if not self.text:
		self.text = _text
	self.callable = function
	self.temp = temporary

# default function
# a callable for options to use as a default
func _default_function():
	pass

# resolve node path
# node paths are set relative to the self and need to be relative to the executor
func _resolve_node_path(path : NodePath) -> NodePath:
	var target = get_node_or_null(executor)
	if target:
		var node = get_node_or_null(path)
		if node:
			return target.get_path_to(node)
	push_error("error path", executor, path)
	return ""
