# Emerald March
# 07-29-2025
# Brian Morris

extends Node2D

# overworld
# handles generating the overworld region map from data and managing interactions with that map

# control variables
var active := false
var _steps := 0
var _is_night_time := false
var _action_buffered := false
var _is_scoping := false
var _is_moving_scope := false
var _scope_idle_timer := 0.0
const _SCOPE_IDLE_SNAP_DELAY := 0.8

# node references
@onready var _player = $OverworldPlayer
@onready var _scope = $Scope
@onready var _ground_layer := $GroundLayer
@onready var _terrain_layer := $TerrainLayer
@onready var _collision_layer := $CollisionLayer
@onready var _location_layer := $LocationLayer

# overworld region data
var _current_region
var _tile_size : int

# ready
# called once at startup
func _ready():
	_tile_size = _ground_layer.tile_set.tile_size.x
	_player.set_center(_tile_size)

# process
# called once per frame
func _process(delta : float):
	if not _current_region:
		return
	
	# fix player location details
	var grid_pos : Vector2i = _ground_layer.local_to_map(_player.global_position)
	var current_speed : float = _current_region.get_speed(grid_pos)
	_player.set_speed(_tile_size * current_speed)
	
	_handle_input(delta)

# handle input
# manages input and user actions
func _handle_input(delta : float):
	# buffer actions and movement until movement ends
	if _player.is_walking():
		if Input.is_action_just_pressed("select"):
			_action_buffered = true
		
		return
	
	# check for a stored action buffer
	if _action_buffered:
		_try_select()
		_action_buffered = false
	
	# check select action
	if Input.is_action_just_pressed("select"):
		_try_select()
		return
	elif Input.is_action_just_pressed("cancel"):
		_toggle_scope()
		return
	
	# check for movement
	var dir := Vector2i.ZERO
	if Input.is_action_pressed("up"):
		dir = Vector2i.UP
	elif Input.is_action_pressed("down"):
		dir = Vector2i.DOWN
	elif Input.is_action_pressed("left"):
		dir = Vector2i.LEFT
	elif Input.is_action_pressed("right"):
		dir = Vector2i.RIGHT
	if dir == Vector2i.ZERO:
		if _is_scoping and _is_moving_scope:
			_scope_idle_timer += delta
			
			if _scope_idle_timer >= _SCOPE_IDLE_SNAP_DELAY:
				_snap_scope()
		return
	
	if _is_scoping:
		if _can_move(_scope.global_position + dir):
			_scope.global_position += dir
			_is_moving_scope = true
	else:
		var target = global_position + Vector2(dir * _tile_size)
		if _can_move(target):
			_player.move_player(target)
		_player.update_player_facing(dir)

# can move
# returns true if tile could be traversed by the player
func _can_move(target : Vector2) -> bool:
	if _is_scoping:
		return _current_region.is_within_borders(target)
	
	var grid_pos = _ground_layer.local_to_map(target)
	var terrain = _current_region.get_terrain(grid_pos)
	var ground = _current_region.get_ground(grid_pos)
	var collision = _current_region.has_collision(grid_pos)
	return _player.can_move(terrain, ground, collision)

# toggle scope
# enable / disables scope
func _toggle_scope():
	_scope.global_position = _player.global_position
	_scope.visible = not _scope.visible
	_player.active = not _scope.visible

# snap scope
# finishes scope movement and snaps it to the center of a tile
func _snap_scope():
	_is_moving_scope = false
	
	var grid_pos = _ground_layer.local_to_map(_scope.global_position)
	
	GameManager.read_scope_data(_current_region.get_data(grid_pos))
	
	grid_pos = _ground_layer.map_to_local(grid_pos)
	grid_pos += Vector2(_tile_size / 2.0, _tile_size / 2.0)
	_scope.global_position = grid_pos

# try select
# attempt to interact with a location
func _try_select():
	pass

# set up
# fills in the world using retrieved data from the files
func set_up(scene_data : Dictionary):
	print(scene_data)
	# Region.new(ground_map, terrain_map, collision_map, location_map)
	# _layer = _current_region 

# set active
# activates self and the player object
func set_active(to_active : bool = true):
	active = to_active
	_player.active = to_active

# finish move
# function called when movement reaches a new tile
func finish_move():
	_player.finish_move()
	_steps += 1
	
	# try to initiate combat
	var encounter_chance = _current_region.get_encounter_chance(_player.global_position)
	var r = GameManager.random_generator.randf()
	if r >= encounter_chance:
		return
	var battle_data = _current_region.get_data(_player.global_position)
	battle_data["is_night"] = _is_night_time
	
	# check to see if battle will have a surprise round
	r = GameManager.random_generator.randf()
	var is_surprise := false
	var is_ambush := false
	if r <= encounter_chance:
		r = GameManager.random_generator.randf()
		if r <= 0.5 or _is_night_time:
			is_ambush = true
		else:
			is_surprise= true
	battle_data["is_ambush"] = is_ambush
	battle_data["is_surprise"] = is_surprise
	
	# start the battle
	GameManager.start_battle(battle_data)
