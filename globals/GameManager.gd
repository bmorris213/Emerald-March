# Emerald March
# 07-22-2025
# Brian Morris

extends Node

# Game Manager
# handles global game information
# as well as manager delegation to control game function

# global manager instances
var _file_manager : FileManager
var _audio_manager : AudioStreamPlayer
var _scene_manager : Node
var _global_ui : CanvasLayer
var random_generator : RandomNumberGenerator

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
var _previous_states := []

# how long, in seconds, to pause controls between states
const _INTERRUPT_DURATION := 0.125

# quit action control variables
var _quit_timer := 0.0
var _trying_to_quit := false
const _QUIT_DELAY := 3 # how long to hold down the quit before it exits

# idle control variables
var _is_idle := false
var _idle_timer := 0.0
const _IDLE_INITIAL_DELAY := 3.4 # how long it takes until idle screen
const _IDLE_FADE_IN := 1.2 # how long it takes for the idle screen to fade in

# ready
# called once at startup
func _ready():
	# set up random number generator
	random_generator = RandomNumberGenerator.new()
	random_generator.randomize()
	random_generator.seed = hash("Alpha State") # TESTING PURPOSES WIP

# setup manager references
# gives access to the other managers in the main scene
func setup_manager_references(root : Node):
	# initialize managers
	_scene_manager = root.get_node("ActiveScene")
	_audio_manager = root.get_node("GlobalAudio")
	_file_manager = FileManager.new()
	
	# grab canvas references
	_global_ui = root.get_node("GlobalUI")
	
	# set up first scene
	_scene_manager.set_scene()
	_switch_state(_GameState.main_menu)

# process
# runs once per frame
func _process(delta : float):
	if _game_state == _GameState.inactive:
		return
	
	# take pause button control
	if Input.is_action_just_pressed("menu"):
		pause()
		return
	
	# update quit timer if present, else catch quit attempts
	if _trying_to_quit:
		# quit try ends
		if not Input.is_action_pressed("quit"):
			_trying_to_quit = false
			_quit_timer = 0.0
			_global_ui.close_quit_warning()
		
		# progress timer
		_quit_timer += delta
		var progress = _quit_timer / _QUIT_DELAY
		_global_ui.update_quit_warning(progress, _QUIT_DELAY)
		
		# timer reaches end
		if _quit_timer >= _QUIT_DELAY:
			_quit_game()
	elif Input.is_action_pressed("quit"):
		_trying_to_quit = true
		_quit_timer = 0.0
	
	# escape idle timer
	if not _game_state == _GameState.overworld and\
	not _game_state == _GameState.free_roam and\
	not _game_state == _GameState.dungeon:
		return
	
	# toggle idle state
	if not Input.is_anything_pressed():
		_idle_timer += delta
	elif _idle_timer != 0.0:
		_idle_timer = 0.0
		if _is_idle:
			_is_idle = false
			_global_ui.end_idling()
	
	# manage idle state
	if _is_idle:
		var progress := _idle_timer - _IDLE_INITIAL_DELAY
		var a := progress * (1.0 / _IDLE_FADE_IN)
		a = clampf(a, 0.0, 1.0)
		_global_ui.update_idle_fade(a)
	elif _idle_timer >= _IDLE_INITIAL_DELAY and _idle_timer <= _IDLE_INITIAL_DELAY * 3:
		_is_idle = true
		_global_ui.start_idling()

# switch state
# changing from gameplay context to another, pausing input listeners
func _switch_state(new_state : _GameState):
	# escape redundant calls
	if _game_state == new_state:
		return
	
	# shut down previous controls
	match _game_state:
		_GameState.inactive:
			pass
		_GameState.main_menu:
			_scene_manager.current_scene.set_active(false)
		_GameState.paused:
			_global_ui.set_pause_active(false)
		_GameState.dialogue:
			_global_ui.set_dialogue_active(false)
		_:
			_scene_manager.current_scene.active = false
	
	# potentially switch scenes
	var scene_state_map := {
		_GameState.main_menu : _scene_manager.SceneID.MainMenu,
		_GameState.overworld : _scene_manager.SceneID.Overworld,
		_GameState.free_roam : _scene_manager.SceneID.Location,
		_GameState.dungeon : _scene_manager.SceneID.Dungeon
	}
	var scene_states := scene_state_map.keys()
	if _game_state in scene_states and\
	new_state in scene_states:
		_scene_manager.set_scene(scene_state_map[new_state])
		_previous_states = [new_state]
	
	# disable controls for a brief pause
	_game_state = _GameState.inactive
	await get_tree().create_timer(_INTERRUPT_DURATION).timeout
	
	# turn on new controls
	match new_state:
		_GameState.inactive:
			return
		_GameState.main_menu:
			_scene_manager.current_scene.set_active()
		_GameState.paused:
			_global_ui.set_pause_active()
		_GameState.dialogue:
			_global_ui.set_dialogue_active()
		_:
			_scene_manager.current_scene.active = true
	_game_state = new_state

# new game
# move to the first location in the game
func new_game():
	_switch_state(_GameState.overworld)

# pause
# opens or closes the pause menu, or closes dialogue
func pause():
	match _game_state:
		_GameState.inactive:
			return
		_GameState.main_menu:
			_scene_manager.current_scene.close() # returns to root in menu tree
		_GameState.battle:
			_scene_manager.current_scene.toggle_auto_battle()
		_GameState.paused:
			_global_ui.close_pause_menu()
			var next_state = _previous_states.pop_back()
			print(next_state)
			_switch_state(next_state)
		_GameState.dialogue:
			_global_ui.end_dialogue()
			var next_state = _previous_states.pop_back()
			print(next_state)
			_switch_state(next_state)
		_: # any active scenes
			_global_ui.open_pause_menu()
			_previous_states.push_back(_game_state)
			_switch_state(_GameState.paused)

# start dialogue
# begins a dialogue interaction
func start_dialogue(lines : Array[Dialogue]): # WIP replace lines with actor id
	_global_ui.start_dialogue(lines)
	_previous_states.push_back(_game_state)
	_switch_state(_GameState.dialogue)

# start battle
# switches to the battle scene for combat
func start_battle(battle_data : Dictionary): # WIP
	print("COMBAT START")
	print(battle_data)

# main menu
# asks the user for confirmation before returning to main menu
func main_menu():
	var line := Dialogue.new(
		"Exit to Main Menu",
		"Are you sure?\nAll unsaved progress will be lost!",
		{
			"Exit": _return_to_main_menu,
			"Don't": func(): pass
		}
	)
	start_dialogue([line])

# return to main menu
# closes both dialogue and the pause menu to change scenes to main menu
func _return_to_main_menu():
	# close menus
	_global_ui.end_dialogue()
	_global_ui.set_dialogue_active(false)
	_global_ui.close_pause_menu()
	_global_ui.set_pause_active(false)
	
	# change scenes
	_game_state = _GameState.overworld
	_switch_state(_GameState.main_menu)

# quit game
# quickly exit game process from within any context
func _quit_game():
	get_tree().quit() # WIP exit game abruptly : quick cache data first?

# quit game
# asks for confirmation from the user before leaving the game
func quit_game():
	var line := Dialogue.new(
		"Close Game",
		"Are you sure?",
		{
			"Exit": _quit_game,
			"Don't": func(): pass
		}
	)
	start_dialogue([line])
