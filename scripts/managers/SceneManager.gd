# Emerald March
# 07-29-2025
# Brian Morris

extends Node

# Scene Manager
# handles switching, initializing, and loading scenes

class_name SceneManager

# scene references
enum SceneID {
	MainMenu,
	Overworld,
	Battle,
	Location,
	Dungeon
}
const _SCENES := {
	SceneID.MainMenu: "res://scenes/menus/MainMenu.tscn",
	SceneID.Overworld: "res://scenes/overworld/Overworld.tscn",
	SceneID.Battle: "res://scenes/battle/Battle.tscn",
	SceneID.Location: "res://scenes/location/Location.tscn",
	SceneID.Dungeon: "res://scenes/dungeon/Dungeon.tscn",
}
const INITIAL_SCENE := SceneID.MainMenu

# node references
var current_scene : Node

# change scene
# instantiates a scene onto self and hands it data to build itself
func set_scene(scene_id : SceneID = INITIAL_SCENE, data : Dictionary = {}):
	# free up current scene resources
	if current_scene:
		current_scene.queue_free()
	
	# instantiate new scene
	var path : String = _SCENES[scene_id]
	var new_scene : Node = load(path).instantiate()
	add_child(new_scene)
	current_scene = new_scene
	
	# build new scene
	current_scene.set_up(data)
