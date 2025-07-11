# Emerald March
# 07-11-2025
# Brian Morris

extends Node

# Scene Manager
# handles switching, running, initializing, and loading scenes

class_name SceneManager

# control variable
var is_idle : bool

# node references
var _current_scene : Node
var _scene_container : Node

# set container
# establishes a place to initialize scenes
func set_container(target_node : Node):
	_scene_container = target_node

# change scene
# main scene changing function
# instantiates a scene onto self
func set_scene(path : String = Constants.INITIAL_SCENE, scene_data : Dictionary = {}):
	if not _scene_container:
		return
	
	# free up current scene resources
	if _current_scene:
		_current_scene.queue_free()
	
	# instantiate new scene
	var new_scene = load(path).instantiate()
	_scene_container.add_child(new_scene)
	_current_scene = new_scene
	
	_current_scene.set_up(scene_data)

# is in overworld
# returns true if active scene is an overworld type
func is_in_overworld() -> bool:
	return _current_scene.SCENE_NAME == Constants.SCENE_ID.overworld

# start scoping
# initiates "scope" mode of current scene
func start_scoping():
	_current_scene.start_scoping()

# end scoping
# stops the "scope" mode of the current scene
func end_scoping():
	_current_scene.end_scoping()

# move scope
# shifts the scope selector on current scene
func move_scope(direction : Vector2i):
	_current_scene.move_scope(direction)

# move player
# sets the current player's mover to travel 1 tileset unit in a given direction
func move_player(direction : Vector2i) -> bool:
	_current_scene.update_player_facing(direction)
	return _current_scene.try_move(direction)

# at new tile
# function for performing a scene relevant action once movement reaches a new tile
func at_new_tile(_position : Vector2):
	# movement has stopped on a new tile
	_current_scene.took_step(_position)
	if GameManager.control_manager.will_continue_move():
		return
	_current_scene.is_walking = false

# select
# called when the select action is called during active control scheme
func try_select():
	var interactable = _current_scene.get_interact_data()
	
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
			var line := {
				"name" : "Unknown",
				"text" : "Error type of interactble!",
				"choices" : []
			}
			GameManager.menu_manager.start_dialogue([line])
			return
	
	if interactable.hidden:
		_current_scene.set_tile_sprite(Interactable.TILESET_INTERACTABLE_SPRITES[interactable.type])
	if interactable.temporary:
		_current_scene.remove_tile()

# read data
# interaction with a point of interest to just narate something
func _read_data(target : String = "", data : String = ""):
	var line := {}
	
	if target == "" and data == "":
		line = {
			"name" : "Searching...",
			"text" : "Nothing of interest found!",
			"choices" : []
		}
	else:
		line = {
			"name" : target,
			"text" : data,
			"choices" : []
		}
	
	GameManager.menu_manager.start_dialogue([line])

# toggle switch
# use a functioning switch to change something about the scene
func _toggle_switch(_name : String, description : String, target : Dictionary):
	print("switch")
	print(_name, description, target)

# open container
# interaction with a container to potentially gain items
func _open_container(_name : String, description : String, target : Dictionary):
	print("container")
	print(_name, description, target)

# take entrance
# use an interactable to initiate a scene transition
func _take_entrance(_name : String, description : String, target : Dictionary):
	print("entrance")
	print(_name, description, target)

# speak to
# interact with an npc, initiating a dialogue tree
func _speak_to(_name : String, description : String, target : Dictionary):
	print("npc")
	print(_name, description, target)

# call action
# uses a party ability within the active scene
func call_action(action : Dictionary):
	print(action) # WIP

# start battle
# switches scenes to the battle screen when player triggers a random battle
func start_battle(data : Dictionary):
	print(data) # WIP
