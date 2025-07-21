# Emerald March
# 07-22-2025
# Brian Morris

extends Node

# Scene Manager
# handles switching, initializing, and loading scenes

class_name SceneManager

# control variable

# node references
var current_scene : Node
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
	if current_scene:
		current_scene.queue_free()
	
	# instantiate new scene
	var new_scene = load(path).instantiate()
	_scene_container.add_child(new_scene)
	current_scene = new_scene
	
	current_scene.set_up(scene_data)
	current_scene.active = true
