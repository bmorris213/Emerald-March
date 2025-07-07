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
	_current_scene.try_select()

# call action
# uses a party ability within the active scene
func call_action(action : Dictionary):
	print(action) # WIP

# start battle
# switches scenes to the battle screen when player triggers a random battle
func start_battle(data : Dictionary):
	print(data) # WIP
