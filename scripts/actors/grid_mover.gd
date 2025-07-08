# Emerald March
# 07-03-2025
# Brian Morris

extends Node

# Grid Mover
# parses directional input into grid-based movement for an entity on a tilemap

class_name GridMover

# external factors
var move_speed : int

# control variables
var _start_position := Vector2.ZERO
var _current_position := Vector2.ZERO
var _target_position := Vector2.ZERO
var _movement_progress := 0.0

# physical process
# is called once per frame of the physics engine
func _physics_process(delta):
	if _current_position != _target_position:
		_current_position = _start_position.lerp(_target_position, _movement_progress)
		_movement_progress += delta * move_speed
	if _movement_progress >= 1.0:
			_movement_progress = 0.0
			_current_position = _target_position
			GameManager.scene_manager.at_new_tile(_current_position)
# move to
# sets a target and begins motion for the grid mover
func move_to(target : Vector2):
	_start_position = _current_position
	_target_position = target
	_movement_progress = 0.0

# teleport
# instantaneously move position to a target
func teleport(target : Vector2):
	_start_position = target
	_target_position = target
	_current_position = target
	_movement_progress = 0.0

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
