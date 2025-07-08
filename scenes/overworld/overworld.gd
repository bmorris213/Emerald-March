# Emerald March
# 07-08-2025
# Brian Morris

extends Node2D

# overworld
# handles generating the overworld region map from data and managing interactions with that map

# player node references
@onready var _player = $Player
var _animator
var _state_machine

# tilemap node references
@onready var _ground_layer := $GroundLayer
@onready var _terrain_layer := $TerrainLayer
@onready var _collision_layer := $CollisionLayer
@onready var _location_layer := $LocationLayer

# values for player
var is_walking := false # determines sprite animation to play
var _previous_walking_state := false
var steps := 0
var _step_goal : int

# terrain values

# interactable references stored by location
var _locations := {}

# test locations
var locations = [
	Interactable.new(
		Vector2i(7,14), "West Entrance", "The path continues from here around the entire globe.",
		Interactable.INTERACT_TYPES.entrance, { "target_scene" : "overworld",\
			"target_entrance" : "East Entrance"}
	),
	Interactable.new(
		Vector2i(38,14), "East Entrance", "The path continues from here around the entire globe.",
		Interactable.INTERACT_TYPES.entrance, { "target_scene" : "overworld",\
			"target_entrance" : "West Entrance"}
	),
	Interactable.new(
		Vector2i(14,10), "First Town", "A small rural village in the hills.",
		Interactable.INTERACT_TYPES.entrance, { "target_scene" : "location",\
			"target_entrance" : ""}
	),
	Interactable.new(
		Vector2i(28,10), "Cave Tunnel", "The entrance to a cave is visible here.",
		Interactable.INTERACT_TYPES.switch, { "target_action" : "teleport",\
			"target_data" : Vector2i(30,10)}
	),
	Interactable.new(
		Vector2i(12,13), "Forest Clearing", "A peaceful clearing in the woods.",
		Interactable.INTERACT_TYPES.point_of_interest, {}
	),
	Interactable.new(
		Vector2i(34,15), "Cliff Edge", "This cliff overlooks the entirety of the forest below.",
		Interactable.INTERACT_TYPES.point_of_interest, {}
	),
	Interactable.new(
		Vector2i(25,15), "Mountain Dungeon", "Deep in the mountain woods can be found sacred ruins.",
		Interactable.INTERACT_TYPES.entrance, { "target_scene" : "dungeon",\
			"target_entrance" : ""}
	),
	Interactable.new(
		Vector2i(20,20), "Hidden Village", "A small rural village in the hills.",
		Interactable.INTERACT_TYPES.entrance, { "target_scene" : "location",\
			"target_entrance" : ""}, true
	),
	Interactable.new(
		Vector2i(12,16), "Hidden Chest", "In a hollow in a tree there is a small pouch.",
		Interactable.INTERACT_TYPES.container, { "contents" : {"name" : "rock", "count" : 1}}, true
	),
	Interactable.new(
		Vector2i(17,7), "Chest", "There is an overturned carriage with an unopened chest.",
		Interactable.INTERACT_TYPES.container, { "contents" : {"name" : "key", "count" : 1}}, false, true
	),
	Interactable.new(
		Vector2i(27,13), "Locked Gate", "The path into the mountains is blocked by a locked gate.",
		Interactable.INTERACT_TYPES.switch, { "target_action" : "unlock_self",\
			"key" : "key"}, false, true
	),
	Interactable.new(
		Vector2i(10,10), "Mother", "This is where you came from, just now...",
		Interactable.INTERACT_TYPES.npc
	)
]

# set up
# fills in the world using retrieved data from the files
func set_up(scene_data):
	print(scene_data)
	for location in locations:
		_locations[location.position] = location
		if location.hidden:
			_location_layer.set_cell(location.position, -1, Constants.OVERWORLD_EMPTY_TILE)

# ready
# called once at startup
func _ready():
	_animator = $Player/AnimationTree
	_state_machine = _animator.get("parameters/playback")
	_player.teleport(_player.global_position)
	_player.move_speed = 4
	_set_random_goal()
	_collision_layer.visible = false

# process
# called once per frame
func _process(_delta):
	# fix player sprite to current position of mover
	_player.global_position = _player.get_location()
	
	# update sprite animation if walking value changes
	if is_walking != _previous_walking_state:
		_previous_walking_state = is_walking
		if is_walking:
			_state_machine.travel("Walking")
		else:
			_state_machine.travel("Idle")

# try move
# attempts a move in the given direction
func try_move(direction : Vector2i) -> bool:
	_player.global_position = _player.get_location()
	var target = _player.global_position + Vector2(direction * _collision_layer.tile_set.tile_size)
	if _can_move_to(_player.global_position, target):
		_player.move_to(target)
		is_walking = true
		return true
	return false

# update player facing
# changes the animation direction for the player
func update_player_facing(direction : Vector2i):
	_animator.set("parameters/Idle/blend_position", direction)
	_animator.set("parameters/Walking/blend_position", direction)

# can move to
# tests the line between start and stop if player movement would be valid
func _can_move_to(start_pos : Vector2, end_pos : Vector2) -> bool:
	# convert starting and stopping points
	var start_tile = _collision_layer.local_to_map(start_pos)
	var end_tile = _collision_layer.local_to_map(end_pos)
	
	# find the line of tiles on the collision layer
	var points = Utilities.bresenham_line(start_tile, end_tile)
	
	# for first collision tile hit, we can't make this movement
	for point in points:
		var tile_data = _collision_layer.get_cell_tile_data(point)
		if tile_data:
			return false
	
	return true

# took step
# function called after every tile of movement
func took_step(_position : Vector2):
	steps += 1
	print(steps, " : " ,_step_goal)
	if steps >= _step_goal:
		_set_random_goal()
		steps = 0
		print("battle start")

# random goal
# assigns a new random step goal to reach before battle
func _set_random_goal():
	var r = GameManager.random_generator.randf()
	_step_goal = lerp(6, 15, r)

# get interact data
# returns any interaction custom data at a certain tile position
func get_interact_data() -> Interactable:
	# check on top of player
	var grid_pos = _collision_layer.local_to_map(_player.global_position)
	
	# check in front of player
	if not grid_pos in _locations:
			grid_pos += Vector2i(_animator.get("parameters/Idle/blend_position"))
	
	if grid_pos in _locations:
		return _locations[grid_pos]
	
	return Interactable.new() # the empty interactable

# set tile sprite
# reveal a hidden tile by finding its sprite from its data
func set_tile_sprite(target : Vector2i):
	var tile_pos = _collision_layer.local_to_map(_player.global_position)
	print('_location_layer.set_cell(tile_pos, -1, target)')

# remove tile
# deletes a tile at a specific position from the locations layer
func remove_tile(pos : Vector2i = _player.global_position):
	print('delete tile')
