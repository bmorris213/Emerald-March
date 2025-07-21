# Emerald March
# 07-22-2025
# Brian Morris

extends Node2D

# overworld
# handles generating the overworld region map from data and managing interactions with that map

const SCENE_NAME := Constants.SCENE_ID.overworld

# player control
var active := false
var player_has_boat := false
var player_in_cart := false
var _action_buffered := false

# node references
@onready var _player = $Player
@onready var _animator := $Player/AnimationTree
@onready var _state_machine = $Player/AnimationTree.get("parameters/playback")

# values for player
var _is_walking := false
var _has_been_walking := false # don't interrupt walking animations
var _is_scoping := false
var _steps := 0

# overworld region data
var _current_region

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
	_current_region = Region.new(self) # WIP
	_current_region.set_up_region(locations)

# ready
# called once at startup
func _ready():
	_player.teleport(_player.global_position)

# process
# called once per frame
func _process(delta):
	if not active:
		return
	
	# fix player sprite to current position of mover and update data
	_player.global_position = _player.get_location()
	_player.move_speed = _current_region.get_speed(_player.global_position)
	
	# update sprite animation if walking value changes
	if _is_walking != _has_been_walking:
		_has_been_walking = _is_walking
		if _is_walking:
			_state_machine.travel("Walking")
		else:
			_state_machine.travel("Idle")
	
	_handle_input()

# handle input
# manages input and user actions
func _handle_input():
	# buffer actions and movement until movement ends
	if _is_walking:
		if Input.is_action_just_pressed("select"):
			_action_buffered = true
		
		# test for the end of movement
		if not _player.is_moving():
			_finish_move()
		return
	
	# check for a stored action buffer
	if _action_buffered:
		_try_select()
		_action_buffered = false
	
	# check select action
	if Input.is_action_just_pressed("select"):
		_try_select()
	
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
	if dir != Vector2i.ZERO:
		if _can_move(dir):
			_move_player(dir)
		_update_player_facing(dir)

# can move
# returns true if tile could be traversed by the player
func _can_move(direction : Vector2) -> bool:
	var target = _player.global_position + Vector2(direction * _current_region.tile_size)
	
	# validate terrain
	if player_in_cart and not _current_region.get_terrain(target) == Region.TerrainType.roads:
		return false
	
	# validate ground
	var ground = _current_region.get_ground(target)
	if ground == Region.GroundType.none or ground == Region.GroundType.deep_water:
		return false
	if ground == Region.GroundType.shallow_water and not player_has_boat:
		return false
	
	# validate collision
	return not _current_region.has_collision(target)

# move player
# sets the player's grid mover to target the next tile over
func _move_player(direction : Vector2i):
	var target = _player.global_position + Vector2(direction * _current_region.tile_size)
	_player.move_to(target)
	_is_walking = true

# update player facing
# changes the animation direction for the player
func _update_player_facing(direction : Vector2i):
	_animator.set("parameters/Idle/blend_position", direction)
	_animator.set("parameters/Walking/blend_position", direction)

# finish move
# function called when movement reaches a new tile
func _finish_move():
	_is_walking = false
	_steps += 1
	
	# try to initiate combat
	var r = GameManager.random_generator.randf()
	var encounter_chance = _current_region.get_encounter_chance(_player.get_location(false))
	if r < encounter_chance:
		_action_buffered = false
		GameManager.start_battle(_current_region.get_battle_data(_player.get_location(false)))

# try select
# attempt to interact with a location
func _try_select():
	var interactable = _current_region.get_interactable(_player.global_position)
	
	if interactable.type == Interactable.INTERACT_TYPES.empty:
		_read_data()
		return
	
	match interactable.type:
		Interactable.INTERACT_TYPES.point_of_interest:
			_read_data(interactable.key_string, interactable.description)
		Interactable.INTERACT_TYPES.switch:
			_toggle_switch(interactable.key_string, interactable.description, interactable.target_data)
		Interactable.INTERACT_TYPES.container:
			_open_container(interactable.key_string, interactable.description, interactable.target_data)
		Interactable.INTERACT_TYPES.entrance:
			_take_entrance(interactable.key_string, interactable.description, interactable.target_data)
		Interactable.INTERACT_TYPES.npc:
			_speak_to(interactable.key_string, interactable.description, interactable.target_data)
		_:
			push_error("Overworld: Unknown type of interactable!")
			return

# read data
# interaction with a point of interest to just narate something
func _read_data(_name : String = "", description : String = ""):
	var line
	
	if _name == "" and description == "":
		line = Dialogue.new("Searching...", "Nothing of interest found!")
	else:
		line = Dialogue.new(_name, description)
	
	GameManager.start_dialogue([line])

# toggle switch
# use a functioning switch to change something about the scene
func _toggle_switch(_name : String, description : String, target : Dictionary):
	print("switch")
	print(_name, description, target) # WIP

# open container
# interaction with a container to potentially gain items
func _open_container(_name : String, description : String, target : Dictionary):
	print("container")
	print(_name, description, target) # WIP

# take entrance
# use an interactable to initiate a scene transition
func _take_entrance(_name : String, description : String, target : Dictionary):
	print("entrance")
	print(_name, description, target) # WIP

# speak to
# interact with an npc, initiating a dialogue tree
func _speak_to(_name : String, description : String, target : Dictionary):
	print("npc")
	print(_name, description, target) # WIP
