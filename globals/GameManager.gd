# Emerald March
# 07-22-2025
# Brian Morris

extends Node

# Game Manager
# handles global game information
# as well as manager delegation to control game function

# global manager instances
var _file_manager
var _audio_manager
var _scene_manager
var random_generator
var _saved_random_state
var _global_ui

# which context the game is running in
enum _GameState {
	inactive,
	main_menu,
	overworld,
	battle,
	paused,
	dialogue,
	free_roam,
	dungeon
}
var _game_state := _GameState.inactive
var _previous_state := _GameState.inactive

# interrupt variables
const _MIN_INTERRUPT_DURATION := 0.125

# ready
# called once at startup
func _ready():
	# set up managers
	_file_manager = preload(Constants.SCENES[Constants.SCENE_ID.file_manager])
	_file_manager = FileManager.new()
	_audio_manager = preload(Constants.SCENES[Constants.SCENE_ID.audio_manager])
	_audio_manager = AudioManager.new()
	_scene_manager = preload(Constants.SCENES[Constants.SCENE_ID.scene_manager])
	_scene_manager = SceneManager.new()
	
	random_generator = RandomNumberGenerator.new()
	random_generator.seed = hash(Constants.RNG_SEED)
	_saved_random_state = random_generator.state

# setup global scene
# gives managers access to the nodes in the global main scene
func setup_global_scene(root : Node):
	# initialize managers
	_global_ui = root.get_node("GlobalUI")
	_scene_manager.set_container(root.get_node("ActiveScene"))
	_audio_manager.set_global_player(root.get_node("GlobalAudio"))
	
	# set up first scene
	_scene_manager.set_scene()
	_game_state = _GameState.overworld # WIP Change to main menu

# process
# runs once per frame
func _process(_delta):
	if _game_state == _GameState.inactive:
		return
	
	if Input.is_action_just_pressed("menu"):
		pause()

# switch state
# changing from gameplay context to another, pausing input listeners
func _switch_state(new_state : _GameState):
	# shut down previous controls
	match _game_state:
		_GameState.inactive:
			return
		_:
			_scene_manager.current_scene.active = false
	_game_state = _GameState.inactive
	
	# wait a brief pause
	
	await get_tree().create_timer(_MIN_INTERRUPT_DURATION).timeout
	
	# turn on new controls
	_game_state = new_state
	match _game_state:
		_GameState.inactive:
			return
		_GameState.paused:
			pass
		_GameState.dialogue:
			pass
		_:
			_scene_manager.current_scene.active = true

# quit game
# shut down the game
func quit_game():
	get_tree().quit() # WIP exit game abruptly

# pause
# opens or closes the pause menu, or closes dialogue
func pause():
	match _game_state:
		_GameState.inactive:
			return
		_GameState.main_menu:
			pass # main menu "menu button" function
		_GameState.battle:
			pass # battle "menu button" function
		_GameState.paused:
			_global_ui.toggle_pause()
			_switch_state(_previous_state)
		_GameState.dialogue:
			if _global_ui.can_idle:
				_switch_state(_previous_state)
			else:
				# dialogue is still running
				_global_ui.end_dialogue()
		_: # any active scenes
			_previous_state = _game_state
			_global_ui.toggle_pause()
			_switch_state(_GameState.paused)

# start dialogue
# begins a dialogue interaction
func start_dialogue(lines : Array[Dialogue]): # WIP replace lines with actor id
	_previous_state = _game_state
	_global_ui.start_dialogue(lines)
	_switch_state(_GameState.dialogue)

# start battle
# switches to the battle scene for combat
func start_battle(battle_data : Dictionary): # WIP
	print("COMBAT START")
	print(battle_data)
