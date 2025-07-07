# Rise of the Dragon King
# 07-05-2025
# Brian Morris

extends Node

# Game Manager
# handles global game information
# as well as manager delegation to control game function

# global manager instances
var control_manager
var file_manager
var menu_manager
var audio_manager
var scene_manager
var random_generator
var _saved_random_state

# stored data from player
var _quick_options := {
	Vector2i.ZERO : "speak",
	Vector2i.UP : "ability 1",
	Vector2i.DOWN : "ability 3",
	Vector2i.LEFT : "ability 4",
	Vector2i.RIGHT : "ability 2"
}

# ready
# called once at startup
func _ready():
	# set up managers
	control_manager = preload(Constants.SCENES[Constants.SCENE_ID.control_manager])
	control_manager = ControlManager.new()
	file_manager = preload(Constants.SCENES[Constants.SCENE_ID.file_manager])
	file_manager = FileManager.new()
	menu_manager = preload(Constants.SCENES[Constants.SCENE_ID.menu_manager])
	menu_manager = MenuManager.new()
	audio_manager = preload(Constants.SCENES[Constants.SCENE_ID.audio_manager])
	audio_manager = AudioManager.new()
	scene_manager = preload(Constants.SCENES[Constants.SCENE_ID.scene_manager])
	scene_manager = SceneManager.new()
	random_generator = RandomNumberGenerator.new()
	random_generator.seed = hash(Constants.RNG_SEED)
	_saved_random_state = random_generator.state

# setup global scene
# gives managers access to the nodes in the global main scene
func setup_global_scene(root : Node):
	scene_manager.set_container(root.get_node("ActiveScene"))
	menu_manager.set_canvas(root.get_node("GlobalUI"))
	audio_manager.set_global_player(root.get_node("GlobalAudio"))
	
	# set up first scene
	scene_manager.set_scene()

# process
# called once per frame
func _process(delta : float):
	# ask ControlManager to handle input and take action
	control_manager.handle_input(delta)
	
	# pass delta to managers
	control_manager.process(delta)
	menu_manager.process(delta)

# get quick action
# returns the action assigned to that direction choice in the quick key menu
func get_quick_action(direction : Vector2i) -> Dictionary:
	return { "name" : _quick_options[direction] }
