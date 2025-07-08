# Emerald March
# 07-07-2025
# Brian Morris

extends Control

# Menu
# useful class for menu interactions. A JRPG is 80% menus, afterall!

class_name Menu

# base menu information
var _selected_index := 0
@export var h_locked := false
@export var v_locked := false
@export var row_size := 0

# game objects
var _options : Array[Option] = []
var _option_container : Node

# export variables
var _selector_icon : Node
@export var offset := Vector2(-20, 0)

# ready
# called once on startup of the scene
func _ready():
	# look under menu for option container and selector
	var selector = find_child(Constants.SELECTOR_NAME)
	var container = find_child(Constants.OPTION_CONTAINER_NAME)
	if selector:
		_selector_icon = selector
	
	if container:
		_option_container = container
		var children = _option_container.get_children()
		for child in children:
			if child is Option:
				_options.append(child as Option)

# lock movement
# disables selector movement along one or both axis
func lock_movement(lock_v : bool = false, lock_h : bool = false):
	v_locked = lock_v
	h_locked = lock_h

# update selection
# used to change UI elements to update a new selection
func _update_selection():
	if _selector_icon and _selected_index < _options.size() and _selected_index >= 0:
		_selector_icon.global_position = _options[_selected_index].global_position + offset
		_selector_icon.rotation = _options[_selected_index].rotation

# move selector
# function to change the menu selection
func move_selector(direction : Vector2i):
	if _options.size() == 0:
		return
	
	var amount = 1
	if direction == Vector2i.UP or direction == Vector2i.DOWN:
		amount = row_size * direction.y
		if v_locked:
			amount = 0
	elif direction == Vector2i.LEFT or direction == Vector2i.RIGHT:
		amount = direction.x
		if h_locked:
			amount = 0
	_selected_index = (_selected_index + amount + _options.size()) % _options.size()
	call_deferred("_update_selection")

# move selector to
# manually choose a selection from the menu
func move_selector_to(selection : int):
	if selection < 0 or selection >= _options.size():
		return
	
	_selected_index = selection
	call_deferred("_update_selection")

# on select
# call the function on the currently chosen option
func on_select():
	if not _options:
		return
	if _selected_index >= _options.size():
		return
	
	_options[_selected_index].callable.call()

# create option
# makes a new label option using choice information
func create_option(choice : Dictionary):
	var label = Label.new()
	
	var label_settings = load("res://assets/fonts/label_font.tres")
	label.set("label_settings", label_settings)
	label.set("size_flags_horizontal", 2)
	label.set("custom_minimum_size", Vector2(100, 0))
	label.set("vertical_alignment", 1)
	label.set("horizontal_alignment", 1)
	
	label.text = choice.text
	
	var option = Option.new(label, choice.function, true)
	_option_container.add_child(option)
	_options.append(option)

# unset choices
# delete all menu choices
func unset_choices(full_delete : bool = false):
	for option in _options:
		if option.temp or full_delete:
			option.queue_free()
			_options.erase(option)

# toggle selector
# turns on or off the selector icon
func toggle_selector():
	_selector_icon.visible = not _selector_icon.visible
