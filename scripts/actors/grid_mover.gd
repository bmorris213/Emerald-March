# Emerald March
# 07-15-2025
# Brian Morris

extends Node

# Grid Mover
# parses directional input into grid-based movement for an entity on a tilemap

class_name GridMover

# external factors
var move_speed : int

# control variables
var _current_position := Vector2.ZERO
var _target_position := Vector2.ZERO

# physical process
# is called once per frame of the physics engine
func _physics_process(delta):
	# no movement is needed
	if _current_position == _target_position:
		return
	
	# plan movement
	var direction = (_target_position - _current_position).normalized()
	var distance_to_move = delta * move_speed
	var remaining_distance = _current_position.distance_to(_target_position)
	
	# check if movement would finish progress
	if distance_to_move >= remaining_distance:
		_current_position = _target_position
		return
	
	# move
	_current_position += direction * distance_to_move

# move to
# sets a target and begins motion for the grid mover
func move_to(target : Vector2):
	_target_position = target

# teleport
# instantaneously move position to a target
func teleport(target : Vector2):
	_target_position = target
	_current_position = target

# ism oving
# returns if progress is still being made towards movement
func is_moving() -> bool:
	return _current_position != _target_position

# get location
# returns a location
# if snap is true, returns a snapped location
func get_location(snap : bool = false) -> Vector2:
	if snap:
		return Vector2i(_current_position)
	else:
		return _current_position
