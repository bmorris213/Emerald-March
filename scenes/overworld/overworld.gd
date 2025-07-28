# Emerald March
# 07-29-2025
# Brian Morris

extends Node2D

# overworld
# handles generating the overworld region map from data and managing interactions with that map

# control variables
var active := false
var _elapsed_time := 0.0
const _NIGHT_START := 18.0
const _NIGHT_END := 24.0
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

# process
# called once per frame
func _process(delta : float):
	if not _current_region:
		return
	
	if not active:
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
		if _can_move(_scope.global_position + Vector2(dir)):
			_scope.global_position += Vector2(dir)
			_scope_idle_timer = 0.0
			GameManager.update_scope_title()
			GameManager.read_scope_data()
			_is_moving_scope = true
	else:
		var target = _player.global_position + Vector2(dir * _tile_size)
		target = _ground_layer.map_to_local(_ground_layer.local_to_map(target))
		if _can_move(target):
			_player.move_player(target)
			_current_region.player_location = _ground_layer.local_to_map(target)
		_player.update_player_facing(dir)

# can move
# returns true if tile could be traversed by the player
func _can_move(target : Vector2) -> bool:
	var grid_pos = _ground_layer.local_to_map(target)
	if not _current_region.is_within_border(grid_pos):
		return false
	
	if _is_scoping:
		return true
	
	var terrain = _current_region.get_terrain(grid_pos)
	var ground = _current_region.get_ground(grid_pos)
	var collision = _current_region.has_collision(grid_pos)
	return _player.can_move(terrain, ground, collision)

# toggle scope
# enable / disables scope
func _toggle_scope():
	_scope.global_position = _player.global_position
	_scope_idle_timer = 0.0
	_is_moving_scope = false
	GameManager.read_scope_data()
	GameManager.update_scope_title()
	GameManager.toggle_scope_data_reader()
	_scope.visible = not _scope.visible
	_player.active = not _scope.visible
	_is_scoping = _scope.visible
	if _is_scoping:
		_scope.get_child(0).set_current()
	else:
		_player.get_child(0).set_current()
	_snap_scope()

# snap scope
# finishes scope movement and snaps it to the center of a tile
func _snap_scope():
	_is_moving_scope = false
	
	var grid_pos = _ground_layer.local_to_map(_scope.global_position)
	
	GameManager.update_scope_title(_current_region.get_title(grid_pos))
	
	grid_pos = _ground_layer.map_to_local(grid_pos)
	grid_pos += Vector2(_tile_size / 2.0, _tile_size / 2.0)
	_scope.global_position = grid_pos

# try select
# attempt to interact with a location
func _try_select():
	var grid_pos = _ground_layer.local_to_map(_player.global_position)
	var loc = _current_region.get_location(grid_pos)
	var line : Dialogue
	
	# check for location
	if not loc == {} and not _is_scoping:
		line = Dialogue.new(
			loc["key_string"],
			"Enter the %s?" % [Region.LocationType.keys()[loc["type"]]],
			{
				"Enter" : func():
			if not _current_region.tile_is_explored(grid_pos):
				_current_region.explore_location(loc)
			GameManager.enter_location(loc),
				"Don't" : func(): pass
			}
		)
		GameManager.start_dialogue([line])
		return
	
	# exploration feature
	if _is_scoping:
		grid_pos = _ground_layer.local_to_map(_scope.global_position)
		
		loc = _current_region.get_location(grid_pos)
		
		if not loc == {}:
			GameManager.read_scope_data(loc)
		
		GameManager.read_scope_data(_current_region.get_data(grid_pos))
		return
	
	if _current_region.tile_is_explored(grid_pos):
		line = Dialogue.new(
			_current_region.get_title(grid_pos),
			"There is nothing here."
		)
		GameManager.start_dialogue([line])
		return
	
	var detail := "Explore the land?\nIt seems like it might be a "
	var terrain : Region.TerrainType = _current_region.get_terrain(grid_pos)
	match terrain:
		Region.TerrainType.roads:
			detail += "simple enough task..."
		Region.TerrainType.plains:
			detail += "somewhat difficult task..."
		Region.TerrainType.wilds:
			detail += "somewhat difficult task..."
		Region.TerrainType.hills:
			detail += "mighty task..."
		Region.TerrainType.woods:
			detail += "mighty task..."
		Region.TerrainType.mountains:
			detail += "mighty task..."
	line = Dialogue.new(
		"Explore",
		detail,
		{
			"Explore" : func():
		_elapsed_time += 3.5 / (_current_region.get_speed(grid_pos) * 2)
		var result = _current_region.search_tile(grid_pos)
		line = Dialogue.new(
			_current_region.get_title(grid_pos),
			result)
		GameManager.start_dialogue([line]),
			"Don't" : func(): pass
		}
	)
	GameManager.start_dialogue([line])

# build tilemap
# constructs a tilemap from map data retrieved from file
func _build_tilemap(layer : TileMapLayer, data_map : Array):
	for i in data_map.size():
		for j in data_map[i].size():
			var tile_id = data_map[i][j]
			layer.set_cell(Vector2i(j, i), 0, tile_id)

# set up
# fills in the world using retrieved data from the files
func set_up(scene_data : Dictionary):
	var _ground = scene_data["ground_map"]
	var _terrain = scene_data["terrain_map"]
	var _collisions = scene_data["collision_map"]
	var _locations = scene_data["locations"]
	_current_region = Region.new(_ground, _terrain, _collisions, _locations)
	_current_region.entrances = scene_data["entrances"]
	
	var _map = _current_region.get_atlas_map("ground")
	_build_tilemap(_ground_layer, _map)
	_map = _current_region.get_atlas_map("terrain")
	_build_tilemap(_terrain_layer, _map)
	_map = _current_region.get_atlas_map("collision")
	_build_tilemap(_collision_layer, _map)
	_map = _current_region.get_atlas_map("location")
	_build_tilemap(_location_layer, _map)
	
	_player.teleport_to(_ground_layer.map_to_local(_current_region.player_location))

# set active
# activates self and the player object
func set_active(to_active : bool = true):
	active = to_active
	_player.active = to_active

# finish move
# function called when movement reaches a new tile
func finish_move():
	await get_tree().process_frame
	
	# move animation to idle
	var can_idle := not Input.is_action_pressed("up")
	can_idle = can_idle and not Input.is_action_pressed("down")
	can_idle = can_idle and not Input.is_action_pressed("left")
	can_idle = can_idle and not Input.is_action_pressed("right")
	_player.finish_move(can_idle)
	
	# advance time
	var grid_pos = _ground_layer.local_to_map(_player.global_position)
	_elapsed_time += 1.2 / (_current_region.get_speed(grid_pos) * 2)
	if _is_night_time:
		if _elapsed_time >= _NIGHT_END:
			_is_night_time = false
			_elapsed_time = 0.0
			print("become day")
	elif _elapsed_time >= _NIGHT_START:
		_is_night_time = true
		print("become night")
	
	# try to initiate combat
	var encounter_chance = _current_region.get_encounter_chance(grid_pos)
	var r = GameManager.random_generator.randf()
	if _is_night_time:
		encounter_chance += 50.0
	if r >= encounter_chance:
		return
	var battle_data = _current_region.get_data(grid_pos)
	battle_data["is_night"] = _is_night_time
	
	# check to see if battle will have a surprise round
	r = GameManager.random_generator.randf()
	var is_surprise := false
	var is_ambush := false
	if _is_night_time:
		is_ambush = true
	elif r <= encounter_chance:
		r = GameManager.random_generator.randf()
		if r <= 0.5 or _is_night_time:
			is_ambush = true
		else:
			is_surprise= true
	battle_data["is_ambush"] = is_ambush
	battle_data["is_surprise"] = is_surprise
	
	# start the battle
	
	GameManager.start_battle(battle_data)
