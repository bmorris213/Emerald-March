# Emerald March
# 07-29-2025
# Brian Morris

extends Sprite2D

# Overworld Player
# encapsulates the player character on the overworld map

class_name OverworldPlayer

# node references
@onready var _mover := $GridMover
@onready var _animator := $AnimationTree
@onready var _state_machine = $AnimationTree.get("parameters/playback")

# control variables
var active := false
var player_has_boat := false
var player_in_cart := false

# tracking values
var _is_walking := false

# process
# called once per frame
func _process(_delta):
	# update global position to mover
	global_position = _mover.get_location()

# can move
# returns true if tile could be traversed by the player
func can_move(_terrain : Region.TerrainType, _ground : Region.GroundType, _collision : bool) -> bool:
	if not active:
		return false
	
	# validate terrain
	if player_in_cart and not _terrain == Region.TerrainType.roads:
		return false
	
	# validate ground
	if _ground == Region.GroundType.none or _ground == Region.GroundType.deep_water:
		return false
	if _ground == Region.GroundType.shallow_water and not player_has_boat:
		return false
	
	# validate collision
	return not _collision

# move player
# sets the player's grid mover to target the next tile over
func move_player(target : Vector2):
	if not active:
		return
	
	_mover.move_to(target)
	_is_walking = true
	_state_machine.travel("Walking")

# update player facing
# changes the animation direction for the player
func update_player_facing(direction : Vector2i):
	if not active:
		return
	
	_animator.set("parameters/Idle/blend_position", direction)
	_animator.set("parameters/Walking/blend_position", direction)

# set speed
# updates grid mover's movement speed
func set_speed(new_speed : float):
	_mover.move_speed = new_speed

# set center
# moves the player to the center of tiles
func set_center(tile_size : int):
	_mover.teleport(Vector2(tile_size / 2.0, tile_size / 2.0))

# is walking
# returns whether or not the player is still moving
func is_walking() -> bool:
	return _is_walking

# finish move
# update is_walking
func finish_move():
	_is_walking = false
	_state_machine.travel("Idle")
