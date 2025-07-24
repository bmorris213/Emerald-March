# Emerald March
# 07-22-2025
# Brian Morris

extends Control

# DialogueBox
# displays readable text and information during NPC speach or naration
# and manages a choice menu tree for when dialogue has branching options

# text speed settings
const TYPING_SPEED := {
	"slow" : 12,
	"medium" : 18,
	"fast" : 24
}
const _RAPID_TYPING_MULTIPLIER := 2.75

# control variabls
var active := false
var _rapid := false
var _dialogue_queue := []
var _is_animating := false # a line is currently being ran
var _current_line

# animation values
var _timer := 0.0
var _buffer_string := ""
var _line_index := 0
var _typing_speed = TYPING_SPEED.slow

# node references
@onready var _text_box := $TextBox/Text
@onready var _title_box := $TitleBox/Title
@onready var _choice_menu := $ChoiceMenu

# process
# called once per frame
func _process(delta : float):
	# escape if dialogue interaction is not valid
	if not active:
		return
	
	# check for select key press
	if Input.is_action_just_pressed("select"):
		_show_next_line()
		return
	
	if _choice_menu.active and Input.is_action_just_pressed("cancel"):
		_choice_menu.active = false
		_choice_menu.visible = false
		_choice_menu.unset_choices(true)
		GameManager.pause()
		return
	
	# check for rapid key press
	_rapid = Input.is_action_pressed("cancel")
	
	# escape if we aren't animating
	if not _is_animating:
		return
	
	# animation finish condition
	if _line_index >= _current_line.text.length():
		_finish_line()
		return
	
	# increase timer until a character can be displayed
	var increment = delta * _typing_speed
	if (_rapid):
		increment *= _RAPID_TYPING_MULTIPLIER
	_timer += increment
	
	if _timer <= 1.0:
		return
	
	# display another character
	_buffer_string += _current_line.text[_line_index]
	_line_index += 1
	_timer = 0.0
	_text_box.text = _buffer_string

# start dialogue
# function which begins a dialogue interaction with the player
func start_dialogue(lines : Array[Dialogue]):
	_dialogue_queue = lines.duplicate(true)
	_show_next_line()

# show next line
# progresses the dialogue forward by one line of text
func _show_next_line():
	# animation interrupt
	if _is_animating:
		_finish_line()
		return
	
	# if we've got the choice menu active
	if _choice_menu.active:
		_choice_menu.on_select()
		_choice_menu.active = false
		_choice_menu.visible = false
		_choice_menu.unset_choices(true)
	
	# end of all lines
	if _dialogue_queue.is_empty():
		end_dialogue()
		GameManager.pause()
		return
	
	_current_line = _dialogue_queue.pop_front()
	_title_box.text = _current_line.actor_name
	
	_buffer_string = ""
	_text_box.text = _buffer_string
	_is_animating = true
	_timer = 0.0
	_line_index = 0

# function for clearing out current line animation progress
func _finish_line():
	_buffer_string = _current_line.text
	_is_animating = false
	_text_box.text = _buffer_string
	_generate_choices()

# check for choices
# generates choice labels and options, but only if there are choices
func _generate_choices():
	if not _current_line.choices.is_empty():
		var labels = _current_line.choices.keys()
		for label in labels:
			_create_option(label, _current_line.choices[label])
		_choice_menu.lock_movement(false, true)
		_choice_menu.visible = true
		_choice_menu.move_selector_to(0)
		_choice_menu.row_size = 1
		await get_tree().create_timer(0.1).timeout
		_choice_menu.active = true

# create option
# generates a new option and adds it to the menu
func _create_option(_text : String, _function : Callable):
	var option = Option.new(_text, _function, true)
	
	option.label_settings = load("res://assets/fonts/label_font.tres")
	option.set("size_flags_horizontal", 4)
	option.set("size_flags_vertical", 2)
	option.set("vertical_alignment", 1)
	option.set("horizontal_alignment", 1)
	
	_choice_menu.add_option(option)

# end dialogue
# wrapping up dialogue reading
func end_dialogue():
	_is_animating = false
	_buffer_string = ""
	_timer = 0.0
	if _choice_menu.visible:
		_choice_menu.active = false
		_choice_menu.visible = false
		_choice_menu.unset_choices()
