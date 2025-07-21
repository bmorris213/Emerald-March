# Emerald March
# 07-22-2025
# Brian Morris

extends CanvasLayer

# Global UI
# display on screen that maintains through any scene changes

# scene node references
@onready var _quit_warning : Node = $QuittingWarning
@onready var _quit_label : Node = $QuittingWarning/ColorRect/VBoxContainer/Timer
@onready var _header : Node = $ScreenOrganizer/Header
@onready var _footer : Node = $ScreenOrganizer/Footer
@onready var _pause_menu : Node = $ScreenOrganizer/Viewport/PauseMenu
@onready var _dialogue_box : Node = $ScreenOrganizer/Viewport/DialogueBox

var active : bool = false

# quit action control variables
var _quit_timer := 0.0
var _trying_to_quit := false
const _QUIT_DELAY := 3 # how long to hold down the quit before it exits
const _MIN_QUIT_WARNING_OPACITY := 0.4 # the starting opacity for fade in

# idle information
var can_idle := false
var _is_idle := false
var _idle_timer := 0.0
const _IDLE_INITIAL_DELAY := 3.4 # how long it takes until idle screen
const _IDLE_FADE_IN := 1.2 # how long it takes for the idle screen to fade in

# process
# called once per frame
func _process(delta : float):
	# updating status based on active
	_pause_menu.active = active
	_dialogue_box.active = active
	if not active:
		return
	
	# update quit timer if present, else catch quit attempts
	if _trying_to_quit:
		# quit try ends
		if not Input.is_action_pressed("quit"):
			_trying_to_quit = false
			_signal_quitting()
			_quit_timer = 0.0
		
		# progress timer
		_quit_timer += delta
		var progress = _quit_timer / _QUIT_DELAY
		_signal_quitting(progress)
		
		# timer reaches end
		if _quit_timer >= _QUIT_DELAY:
			GameManager.quit_game()
	elif Input.is_action_pressed("quit"):
		_trying_to_quit = true
		_quit_timer = 0.0
	
	# escape idle management
	if not can_idle:
		return
	
	# toggle idle state
	if not Input.is_anything_pressed():
		_idle_timer += delta
	elif _idle_timer != 0.0:
		_idle_timer = 0.0
		if _is_idle:
			_is_idle = false
			_header.modulate.a = 1.0
			_footer.modulate.a = 1.0
			_header.visible = false
			_footer.visible = false
	
	# manage idle state
	if _is_idle:
		var progress := _idle_timer - _IDLE_INITIAL_DELAY
		var a := progress * (1.0 / _IDLE_FADE_IN)
		_header.modulate.a = a
		_footer.modulate.a = a
	elif _idle_timer >= _IDLE_INITIAL_DELAY and _idle_timer <= _IDLE_INITIAL_DELAY * 3:
		_is_idle = true
		_header.visible = true
		_footer.visible = true

# signal quitting
# function to handle signalling to the user they are attempting to quit
func _signal_quitting(progress : float = -1.0):
	# check for default end-signal value of 1.0
	if progress == -1.0:
		_quit_warning.visible = false
		return
	
	# ensure warning is visable
	_quit_warning.visible = true
	
	# ensure progress is 0 > t > 1
	var progress_amount = clampf(progress, 0.0, 1.0)
	
	# lerp quit warning alpha
	var alpha = lerp(_MIN_QUIT_WARNING_OPACITY, 1.0, progress_amount)
	_quit_warning.get_child(0).modulate.a = alpha
	
	# update text
	var remaining_sec = _QUIT_DELAY - (progress_amount * _QUIT_DELAY)
	var string_formatter = { "time" : "%.2f" % remaining_sec}
	var quit_warning := "Quitting in {time}...".format(string_formatter)
	_quit_label.text = quit_warning

# toggle pause
# switches pause menu active state
func toggle_pause():
	# disable idle
	_idle_timer = 0.0
	_is_idle = false
	_header.modulate.a = 1.0
	_footer.modulate.a = 1.0
	
	# toggle pause menu
	if not _pause_menu.visible:
		_pause_menu.open()
	_pause_menu.visible = not _pause_menu.visible
	_header.visible = false
	_footer.visible = false
	can_idle = not can_idle

# start dialogue
# enables dialogue box and begins reading lines
func start_dialogue(lines : Array[Dialogue]):
	# disable idle
	_idle_timer = 0.0
	_is_idle = false
	_header.modulate.a = 1.0
	_footer.modulate.a = 1.0
	_header.visible = false
	_footer.visible = false
	can_idle = false
	
	# toggle dialogue box and begin dialogue
	_dialogue_box.visible = true
	_dialogue_box.start_dialogue(lines)

# end dialogue
# disables dialogue box
func end_dialogue():
	# disable dialogue box
	can_idle = true
	_dialogue_box.visible = false
	_dialogue_box.end_dialogue()
