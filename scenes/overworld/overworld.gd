# Rise of the Dragon King
# 07-07-2025
# Brian Morris

extends Node2D

# overworld
# handles generating the overworld region map from data and managing interactions with that map

# player node references
@onready var _player = $Player
var _animator
var _state_machine

# tilemap node references
@onready var _collision_layer := $CollisionLayer
@onready var _location_layer := $LocationLayer

# values for player
var is_walking := false # determines sprite animation to play
var _previous_walking_state := false
var steps := 0
var _step_goal : int

# time values
var _current_time := 0.0
var _current_day := 0

# test locations
var locations = { # lets just call these INTERACTABLES, since thats the only OBJECT style detail on the world map
	Vector2i(14,10): {
		"name": "Town 1",
		"description": "You approach the small village in the hills",
		"on_enter": func(): GameManager.menu_manager.start_dialogue(
			[{"name" : "Town 1", "text": "You enter the tutorial town..."}])
	},
	Vector2i(20,20): {
		"name": "Forest Dungeon",
		"description": "You find a temple in the woods.",
		"on_enter": func(): GameManager.menu_manager.start_dialogue(
			[{"name" : "Forest Dungeon", "text": "You enter the forest dungeon..."}])
	},
	Vector2i(25,15): {
		"name": "Mountain Dungeon",
		"description": "After a long journey, you find a temple in the mountains.",
		"on_enter": func(): GameManager.menu_manager.start_dialogue(
			[{"name" : "Mountain Dungeon", "text": "You enter the Mountain Dungeon..."}])
	},
	Vector2i(28, 10): {
		"name": "Town 2",
		"description": "You approach the walled town against the cliffside.",
		"on_enter": func(): GameManager.menu_manager.start_dialogue(
			[{"name" : "Town 2", "text": "You enter the second town..."}])
	},
	Vector2i(35, 9): {
		"name": "Far Town",
		"description": "How did you get here? This shouldn't exist.",
		"on_enter": func(): GameManager.menu_manager.start_dialogue(
			[{"name" : "Far Town", "text": "Sorry, but this doesn't exist..."}])
	},
	Vector2i(12, 16): {
		"name": "Secret Location",
		"description": "After wandering the forest, you stumble into a quaint grove.",
		"on_enter": func(): GameManager.menu_manager.start_dialogue(
			[{"name" : "Secret Location", "text": "You enter the clearing in the woods..."}])
	}
}

# set up
# fills in the world using retrieved data
func set_up(scene_data):
	print(scene_data)

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
func get_interact_data() -> Dictionary:
	var result := {}
	
	# check on top of player
	var grid_pos = _collision_layer.local_to_map(_player.global_position)
	var cell_data = _location_layer.get_cell_tile_data(grid_pos)
	
	# check in front of player
	if not cell_data or not cell_data.has_custom_data(Constants.TILESET_INTERACTABLE_TYPE):
			grid_pos += Vector2i(_animator.get("parameters/Idle/blend_position"))
			cell_data = _location_layer.get_cell_tile_data(grid_pos)
	
	# find data
	if cell_data and cell_data.has_custom_data(Constants.TILESET_INTERACTABLE_TYPE):
		for key in cell_data.get_custom_data_keys():
			result[key] = cell_data.get_custom_data(key)
	
	return result
