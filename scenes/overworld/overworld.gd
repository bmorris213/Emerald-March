# Emerald March
# 07-14-2025
# Brian Morris

extends Node2D

# overworld
# handles generating the overworld region map from data and managing interactions with that map

const SCENE_NAME := Constants.SCENE_ID.overworld

# player node references
@onready var _player = $Player
var _animator
var _state_machine
var player_has_boat := false
var player_in_cart := false

# tilemap node references
@onready var _ground_layer := $GroundLayer
@onready var _terrain_layer := $TerrainLayer
@onready var _collision_layer := $CollisionLayer
@onready var _location_layer := $LocationLayer

# values for player
var is_walking := false # determines sprite animation to play
var _previous_walking_state := false
var steps := 0

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

enum GROUND_TYPES {
	normal,
	hazardous,
	dangerous,
	lethal,
	shallow_water,
	deep_water,
	none
}
const GROUND_ATLAS_COORDS := {
	Vector2i(0,1): GROUND_TYPES.normal,
	Vector2i(0,2): GROUND_TYPES.hazardous,
	Vector2i(0,3): GROUND_TYPES.dangerous,
	Vector2i(0,4): GROUND_TYPES.lethal,
	Vector2i(5,2): GROUND_TYPES.shallow_water,
	Vector2i(5,3): GROUND_TYPES.deep_water
}
const GROUND_DANGER_MULTIPLIERS := {
	GROUND_TYPES.normal: 1.0,
	GROUND_TYPES.hazardous: 1.2,
	GROUND_TYPES.dangerous: 1.7,
	GROUND_TYPES.lethal: 2.0,
	GROUND_TYPES.shallow_water: 1.5
}
enum TERRAIN_TYPES {
	plains,
	roads,
	wilds,
	hills,
	woods,
	mountains
}
const TERRAIN_ATLAS_COORDS := {
	Vector2i(1,1): TERRAIN_TYPES.wilds,
	Vector2i(1,2): TERRAIN_TYPES.hills,
	Vector2i(1,3): TERRAIN_TYPES.woods,
	Vector2i(1,4): TERRAIN_TYPES.mountains
}
const TERRAIN_MOVE_SPEEDS := {
	TERRAIN_TYPES.plains : 2.4,
	TERRAIN_TYPES.roads : 2.9,
	TERRAIN_TYPES.wilds : 2.0,
	TERRAIN_TYPES.hills : 1.6,
	TERRAIN_TYPES.woods : 1.6,
	TERRAIN_TYPES.mountains : 1.2
}
const TERRAIN_ENCOUNTER_RATES := {
	TERRAIN_TYPES.plains : 0.03,
	TERRAIN_TYPES.roads : 0.01,
	TERRAIN_TYPES.wilds : 0.06,
	TERRAIN_TYPES.hills : 0.07,
	TERRAIN_TYPES.woods : 0.08,
	TERRAIN_TYPES.mountains : 0.12
}

# set up
# fills in the world using retrieved data from the files
func set_up(scene_data):
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
	var grid_pos = _ground_layer.local_to_map(_player.global_position)
	var position_data = _get_position_data(grid_pos)

# process
# called once per frame
func _process(_delta):
	# fix player sprite to current position of mover
	_player.global_position = _player.get_location()
	
	# update move speed
	var position_data = _get_position_data(_player.global_position)
	_player.move_speed = _ground_layer.tile_set.tile_size.x\
		* TERRAIN_MOVE_SPEEDS[position_data["terrain"]]
	
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
	var target = _player.global_position + Vector2(direction * _ground_layer.tile_set.tile_size)
	if _tile_is_walkable(target):
		_player.move_to(target)
		is_walking = true
		return true
	return false

# update player facing
# changes the animation direction for the player
func update_player_facing(direction : Vector2i):
	_animator.set("parameters/Idle/blend_position", direction)
	_animator.set("parameters/Walking/blend_position", direction)

# took step
# function called after every tile of movement
func took_step(_position : Vector2):
	steps += 1
	var position_data = _get_position_data(_position)
	
	# try combat
	var r = GameManager.random_generator.randf()
	var ground_danger = GROUND_DANGER_MULTIPLIERS[position_data["ground"]]
	var encounter_rate = TERRAIN_ENCOUNTER_RATES[position_data["terrain"]]
	print('rand:', r, '\trate:', encounter_rate, '\tdanger:', ground_danger)
	print(encounter_rate * ground_danger)
	if r < encounter_rate * ground_danger:
		var string_ground = GROUND_TYPES.keys()[position_data["ground"]]
		var string_terrain = TERRAIN_TYPES.keys()[position_data["terrain"]]
		GameManager.scene_manager.start_battle(position_data)

# get interact data
# returns any interaction custom data at a certain tile position
func get_interact_data() -> Interactable:
	# check on top of player
	var grid_pos = _ground_layer.local_to_map(_player.get_location(true))
	
	# check in front of player
	if not grid_pos in _locations:
			grid_pos += Vector2i(_animator.get("parameters/Idle/blend_position"))
			# check in front of player only if there's collision in front of player
			var tile_data = _collision_layer.get_cell_tile_data(grid_pos)
			if not tile_data:
				grid_pos = null
	
	if grid_pos in _locations:
		return _locations[grid_pos]
	
	return Interactable.new() # the empty interactable

# get position data
# returns an object representing the tile at a certain position
func _get_position_data(pos : Vector2) -> Dictionary:
	# grab tilemap position
	var grid_pos = _ground_layer.local_to_map(pos)
	
	# grab atlas coordinates
	var ground = _ground_layer.get_cell_atlas_coords(grid_pos)
	var terrain = _terrain_layer.get_cell_atlas_coords(grid_pos)
	var collision = _collision_layer.get_cell_atlas_coords(grid_pos)
	
	var position_data := {}
	
	# assign ground type
	if ground == Vector2i(-1, -1) or not GROUND_ATLAS_COORDS.has(ground):
		position_data["ground"] = GROUND_TYPES.none
	else:
		position_data["ground"] = GROUND_ATLAS_COORDS[ground]
	# assign terrain type
	if terrain == Vector2i(-1, -1):
		position_data["terrain"] = TERRAIN_TYPES.plains
	elif terrain.x < 5 and terrain.x > 1 and terrain.y > 0:
		position_data["terrain"] = TERRAIN_TYPES.roads
	elif not TERRAIN_ATLAS_COORDS.has(terrain):
		position_data["terrain"] = TERRAIN_TYPES.plains
	else:
		position_data["terrain"] = TERRAIN_ATLAS_COORDS[terrain]
	# check for collision
	position_data["collision"] = collision != Vector2i(-1,-1)
	
	return position_data

# tile is walkable
# returns true if tile could be traversed by the player
func _tile_is_walkable(target : Vector2) -> bool:
	var target_details = _get_position_data(target)
	
	# validate terrain
	if player_in_cart and not target_details["terrain"] == TERRAIN_TYPES.roads:
		return false
	
	# validate ground
	var ground = target_details["ground"]
	if ground == GROUND_TYPES.none or ground == GROUND_TYPES.deep_water:
		return false
	if ground == GROUND_TYPES.shallow_water and not player_has_boat:
		return false
	
	# validate collision
	return not target_details["collision"]

# set tile sprite
# reveal a hidden tile by finding its sprite from its data
func set_tile_sprite(target : Vector2i):
	var tile_pos = _collision_layer.local_to_map(_player.get_location(true))
	print('_location_layer.set_cell(tile_pos, -1, target)')

# remove tile
# deletes a tile at a specific position from the locations layer
func remove_tile(pos : Vector2i = _player.get_location(true)):
	print('delete tile')

# start scoping
# initiates scope mode
func start_scoping():
	print('scope')

# end scoping
# finishes scope mode
func end_scoping():
	print('scope not')

# move scope
# shifts position of scope box
func move_scope(direction : Vector2i):
	if direction != Vector2i.ZERO:
		print(direction)
