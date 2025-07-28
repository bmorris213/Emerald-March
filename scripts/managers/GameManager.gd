# Emerald March
# 07-29-2025
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

# initialize
# gives access to the other managers in the main scene
func initialize(root : Node):
	# initialize managers
	_scene_manager = root.get_node("ActiveScene")
	_audio_manager = root.get_node("GlobalAudio")
	_file_manager = FileManager.new()
	
	# grab canvas references
	_global_ui = root.get_node("GlobalUI")
	
	# set up the main menu
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
	if not _scene_manager.current_scene.can_idle:
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
func _switch_state(new_state : _GameState, data : Dictionary = {}):
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
		_GameState.battle:
			_global_ui.set_battle_active(false)
		_:
			_scene_manager.current_scene.set_active(false)
	
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
		_scene_manager.set_scene(scene_state_map[new_state], data)
		_previous_states.push_back(new_state)
	
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
		_GameState.battle:
			_global_ui.set_battle_active()
		_:
			_scene_manager.current_scene.set_active()
	_game_state = new_state

# new game
# move to the first location in the game
func new_game():
	_switch_state(_GameState.overworld, FileManager.get_region())

# pause
# opens or closes the pause menu, or closes dialogue
func pause():
	match _game_state:
		_GameState.inactive:
			return
		_GameState.main_menu:
			_scene_manager.current_scene.close() # returns to root in menu tree
		_GameState.battle:
			_global_ui.toggle_auto_battle()
		_GameState.paused:
			_global_ui.close_pause_menu()
			_switch_state(_previous_states.pop_back())
		_GameState.dialogue:
			_global_ui.end_dialogue()
			_switch_state(_previous_states.pop_back())
		_: # any active scenes
			_global_ui.open_pause_menu()
			_previous_states.push_back(_game_state)
			_switch_state(_GameState.paused)

# start dialogue
# begins a dialogue interaction
func start_dialogue(lines : Array[Dialogue]):
	if _game_state == _GameState.dialogue:
		# await end of dialogue
		while _game_state == _GameState.dialogue:
			await get_tree().process_frame
		
		await get_tree().create_timer(_INTERRUPT_DURATION).timeout
	
	_global_ui.start_dialogue(lines)
	_previous_states.push_back(_game_state)
	_switch_state(_GameState.dialogue)

# start battle
# switches to the battle scene for combat
func start_battle(battle_data : Dictionary):
	# close any paused menu or dialogue
	if _game_state == _GameState.dialogue:
		_global_ui.end_dialogue()
		_game_state = _previous_states.pop_back()
		_global_ui.set_dialogue_active(false)
	if _game_state == _GameState.paused:
		_global_ui.close_pause_menu()
		_game_state = _previous_states.pop_back()
		_global_ui.set_pause_active(false)
	
	# get enemies
	
	# send a battle warning message
	var message_title := "Warning"
	var message := "Enemies approach!"
	if battle_data["is_surprise"]:
		message_title = "Surprise"
		message = "You come across unaware enemies!"
	elif battle_data["is_ambush"]:
		message_title = "Ambush"
		message = "You are ambushed by enemies!"
	start_dialogue([Dialogue.new(message_title,message)])
	
	# wait until dialogue is now active
	await get_tree().create_timer(_INTERRUPT_DURATION).timeout
	
	# await end of dialogue
	while _game_state == _GameState.dialogue:
		await get_tree().process_frame
	
	await get_tree().create_timer(_INTERRUPT_DURATION).timeout
	
	# start battle
	_previous_states.push_back(_game_state)
	_global_ui.open_battle(battle_data)
	_switch_state(_GameState.battle)

# end battle
# switches back to the active scene after combat
func end_battle():
	_global_ui.end_battle()
	_switch_state(_previous_states.pop_back())

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

# exit location
# return to the overworld scene
func exit_location():
	_switch_state(_GameState.overworld, FileManager.get_region())

# enter location
# uses location entrance to visit another region or free roam
func enter_location(location : Dictionary):
	if location["key_string"] == "region":
		var entrance_id = location["entrance_id"]
		var entrance_location = _scene_manager.current_scene._current_region.entrances[entrance_id]
		entrance_location = _scene_manager.current_scene._ground_layer.map_to_local(entrance_location)
		_scene_manager.current_scene._player.teleport_to(entrance_location)
	elif location["key_string"] == "town":
		# close any paused menu or dialogue
		if _game_state == _GameState.dialogue:
			_global_ui.end_dialogue()
			_game_state = _previous_states.pop_back()
			_global_ui.set_dialogue_active(false)
		if _game_state == _GameState.paused:
			_global_ui.close_pause_menu()
			_game_state = _previous_states.pop_back()
			_global_ui.set_pause_active(false)
		_switch_state(_GameState.free_roam)

# end of tile
# finish player movement
func end_of_tile():
	_scene_manager.current_scene.finish_move()

# toggle scope data reader
# function to enable heads up display of scoping information
func toggle_scope_data_reader():
	_global_ui.toggle_scoping()

# update scope title
# changes the title of the tile scope is looking at
func update_scope_title(title : String = ""):
	_global_ui.update_scope_title(title)

# read scope data
# function which passes data to the heads up for the scope
func read_scope_data(data : Dictionary = {}):
	_global_ui.read_scope_data(data)
