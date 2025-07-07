# Rise of the Dragon King
# 07-05-2025
# Brian Morris

extends Node

# Scene Manager
# handles switching, running, initializing, and loading scenes

class_name SceneManager

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
	var data = _current_scene.get_interact_data()
	
	if data == {}:
		_read_data()
	
	var select_type = data.get(Constants.TILESET_INTERACTABLE_TYPE)
	var select_target = data.get(Constants.TILESET_INTERACTABLE_TARGET)
	var select_data = data.get(Constants.TILESET_INTERACTABLE_DATA)
	
	var string_array = Constants.INTERACT_TYPES.keys()
	var match_a = string_array[Constants.INTERACT_TYPES.point_of_interest]
	var match_b = string_array[Constants.INTERACT_TYPES.container]
	var match_c = string_array[Constants.INTERACT_TYPES.entrance]
	var match_d = string_array[Constants.INTERACT_TYPES.npc]
	
	match select_type:
		match_a:
			_read_data(select_target, select_data)
		match_b:
			_open_container(select_target, select_data)
		match_c:
			_take_entrance(select_target, select_data)
		match_d:
			_speak_to(select_target, select_data)

# read data
# interaction with a point of interest to just narate something
func _read_data(target : String = "", data : String = ""):
	print("point of interest")
	if target == "" and data == "":
		print("No problem here.")
	
	print(target, data)

# open container
# interaction with a container to potentially gain items
func _open_container(target : String, data : String):
	print("container")
	print(target, data)

# take entrance
# use an interactable to initiate a scene transition
func _take_entrance(target : String, data : String):
	print("entrance")
	print(target, data)

# speak to
# interact with an npc, initiating a dialogue tree
func _speak_to(target : String, data : String):
	print("npc")
	print(target, data)

# call action
# uses a party ability within the active scene
func call_action(action : Dictionary):
	print(action) # WIP

# start battle
# switches scenes to the battle screen when player triggers a random battle
func start_battle(data : Dictionary):
	print(data) # WIP
