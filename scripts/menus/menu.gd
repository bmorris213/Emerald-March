# Emerald March
# 07-22-2025
# Brian Morris

extends Control

# Menu
# encapsulates a single active menu structure

class_name Menu

# base menu information
var _selected_index := 0

# game objects
var _options : Array[Option] = []
var _option_container : Node
var _selector_icon : Node
const _SELECTOR_NAME := "Selector"
const _OPTION_CONTAINER_NAME := "Options"

# control variables
@export var offset := Vector2(-20, 0)
var active := false
@export var v_locked := false
@export var h_locked := false
@export var row_size := 0

# movement variables
var _direction := Vector2i.ZERO
var _timer := 0.0
var _delay := _MAX_DELAY
const _ACCELERATION := 0.05 # speed up per repeat
const _MAX_DELAY := 0.35 # Initial delay before repeat
const _MIN_DELAY := 0.07 # Fastest speed menu selector moves

# ready
# called once on startup of the scene
func _ready():
	# look under menu for option container and selector
	var selector = find_child(_SELECTOR_NAME)
	var container = find_child(_OPTION_CONTAINER_NAME)
	if selector:
		_selector_icon = selector
	
	if container:
		_option_container = container
		var children = _option_container.get_children()
		for child in children:
			if child is Option:
				_options.append(child as Option)

# process
# called once per frame
func _process(delta : float):
	if not active:
		return
	
	# update acceleration information
	if _direction != Vector2i.ZERO:
		_timer += delta
		
		if _timer >= _delay:
			_move_selector(_direction)
			_timer = 0.0
			_delay = max(_MIN_DELAY, _delay - _ACCELERATION)
	
	# handle select calls
	if Input.is_action_just_pressed("select"):
		_on_select()
	
	_handle_menu_movement()

# handle menu movement
# while the user is holding down a movement key, speed up selection calls
func _handle_menu_movement():
	# check for an end to selector movement
	match(_direction):
		Vector2i.UP:
			if Input.is_action_just_released("up"):
				_end_menu_move()
		Vector2i.DOWN:
			if Input.is_action_just_released("down"):
				_end_menu_move()
		Vector2i.RIGHT:
			if Input.is_action_just_released("right"):
				_end_menu_move()
		Vector2i.LEFT:
			if Input.is_action_just_released("left"):
				_end_menu_move()
	
	# check if we're still moving but need to stop
	if _direction != Vector2i.ZERO:
		if not Input.is_anything_pressed():
			_end_menu_move()
			return
	
	# check for the beginning of a new movement
	if Input.is_action_just_pressed("up"):
		_start_menu_move(Vector2i.UP)
	elif Input.is_action_just_pressed("down"):
		_start_menu_move(Vector2i.DOWN)
	elif Input.is_action_just_pressed("left"):
		_start_menu_move(Vector2i.LEFT)
	elif Input.is_action_just_pressed("right"):
		_start_menu_move(Vector2i.RIGHT)

# start menu move
# starts a movement of the selector for the menu
func _start_menu_move(new_direction : Vector2i):
	_direction = new_direction
	_move_selector(_direction)
	_timer = 0.0
	_delay = _MAX_DELAY

# end menu move
# stops a movement of the selector for the menu
func _end_menu_move():
	_direction = Vector2i.ZERO
	_timer = 0.0
	_delay = _MAX_DELAY

# update selection
# used to change UI elements to update a new selection
func _update_selection():
	if _selector_icon and _selected_index < _options.size() and _selected_index >= 0:
		_selector_icon.global_position = _options[_selected_index].global_position + offset
		_selector_icon.rotation = _options[_selected_index].rotation

# move selector
# function to change the menu selection
func _move_selector(direction : Vector2i):
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

# on select
# call the function on the currently chosen option
func _on_select():
	if not _options:
		return
	if _selected_index >= _options.size():
		return
	var args = _options[_selected_index].arguments.duplicate()
	if args:
		_options[_selected_index].callable.callv(args)
	else:
		_options[_selected_index].callable.call()

# lock movement
# disables selector movement along one or both axis
func lock_movement(lock_v : bool = true, lock_h : bool = true):
	v_locked = lock_v
	h_locked = lock_h

# move selector to
# manually choose a selection from the menu
func move_selector_to(selection : int):
	if selection < 0 or selection >= _options.size():
		return
	
	_selected_index = selection
	call_deferred("_update_selection")

# add option
# adds a new option to the other choices
func add_option(choice : Option):
	_option_container.add_child(choice)
	_options.append(choice)

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

# selector is on
# returns true if the selector is visible
func selector_is_on() -> bool:
	return _selector_icon.visible
