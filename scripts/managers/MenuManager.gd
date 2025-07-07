# Rise of the Dragon King
# 07-07-2025
# Brian Morris

extends Node

# Menu Manager
# handles all nesting menu navigation within the game's UI

class_name MenuManager

# stack of all nesting menus
var _menu_stack := []
var _active_menu : Menu

enum Menus {
	pause_menu,
	quick_menu,
	dialogue_box
}

# node references of global ui
var _canvas : CanvasLayer
var _pause_menu : Menu
var _quick_menu : Menu
var _dialogue_box : Menu
var _tooltip : Label
var _quit_warning : Control

# dialogue management
var rapid : bool
var _dialogue_queue := []
var _is_animating := false
var _current_line

# animation values
var _timer := 0.0
var _buffer_string := ""
var _line_index := 0
var _typing_speed = Constants.TYPING_SPEED.slow

# process
# called once per frame
func process(delta : float):
	if not _is_animating:
		return
	
	if _line_index >= _current_line.text.length():
		_finish_line()
		return
	
	var increment = delta * _typing_speed
	if (rapid):
		increment *= Constants.RAPID_TYPING_MULTIPLIER
	_timer += increment
	
	if _timer <= 1.0:
		return
	
	_buffer_string += _current_line.text[_line_index]
	_line_index += 1
	_timer = 0.0
	_update_box()

# set canvas
# establishes the target canvas layer, as well as grabbing other menu references
func set_canvas(target_node : CanvasLayer):
	_canvas = target_node
	_pause_menu = _canvas.find_child(Constants.PAUSE_MENU_NAME)
	_quick_menu = _canvas.find_child(Constants.QUICK_MENU_NAME)
	_dialogue_box = _canvas.find_child(Constants.DIALOGUE_BOX_NAME)
	_tooltip = _canvas.find_child(Constants.TOOLTIP_NAME)
	_quit_warning = _canvas.find_child(Constants.QUIT_WARNING_NAME)

# attach menu
# open a sub menu and add it to the stack, making it the active menu
func _attach_menu(new_menu : Menu):
	_menu_stack.append(new_menu)
	_active_menu = new_menu
	new_menu.visible = true
	new_menu.move_selector_to(0)

# open menu
# open up a default menu
func open_menu(target : Menus):
	close_menus()
	_canvas.visible = true
	match(target):
		Menus.pause_menu:
			_attach_menu(_pause_menu)
		Menus.quick_menu:
			_attach_menu(_quick_menu)
		Menus.dialogue_box:
			_attach_menu(_dialogue_box)

# close menu
# ends the current menu session
func close_menus():
	_canvas.visible = false
	rapid = false
	for menu in _menu_stack:
		_collapse_menu(menu)
	_menu_stack = []
	_active_menu = null

# collapse menu
# closes a signle menu
func _collapse_menu(menu : Menu):
	menu.move_selector_to(0)
	menu.unset_choices()
	menu.visible = false

# move selector
# changes the highlighted option on the active menu
func move_selector(direction : Vector2i):
	_active_menu.move_selector(direction)

# select
# chooses the highlighted option on the active menu
func select():
	if is_speaking():
		if not _is_animating:
			_active_menu.on_select()
			_clear_options()
		_show_next_line()
	else:
		_active_menu.on_select()

# cancel
# go back a menu layer
func cancel():
	# cancel closes dialogue or base-level menus
	if is_speaking() or _menu_stack.size() == 1:
		close_menus()
		return
	
	_collapse_menu(_active_menu)
	_menu_stack.pop_front()
	_active_menu = _menu_stack[-1]
	_active_menu.grab_focus()

# signal quitting
# update a notification menu with process of quit action
func signal_quitting(progress_amount : float = 0.0):
	# check for signal end, quit warning disappears
	if progress_amount == -1.0:
		_quit_warning.visible = false
		return
	
	# ensure warning is visable
	_quit_warning.visible = true
	
	# ensure progress is 0 > t > 1
	progress_amount = clampf(progress_amount, 0.0, 1.0)
	
	# lerp quit warning alpha
	var alpha = lerp(Constants.MIN_QUIT_WARNING_OPACITY, 1.0, progress_amount)
	_quit_warning.get_child(0).modulate.a = alpha
	
	# update warning text
	var remaining_sec := 3.0 - (progress_amount * 3.0)
	var string_formatter = { "time" : "%.2f" % remaining_sec}
	var quit_warning := "Quitting in {time}...".format(string_formatter)
	_quit_warning.get_child(0).get_child(0).text = quit_warning

# highlight quick key
# changes the visual selection on the quick key menu
func highlight_quick_key(direction : Vector2i):
	var direction_index := {
		Vector2i.ZERO : 0,
		Vector2i.UP : 1,
		Vector2i.DOWN : 3,
		Vector2i.LEFT : 4,
		Vector2i.RIGHT : 2
	}
	_quick_menu.move_selector_to(direction_index[direction])

# viewing menu
# returns true if any menu is currently open
func viewing_menu() -> bool:
	return not _menu_stack.is_empty()

# fade in idle
# make the hud show up slowly
func fade_in_idle(progress : float):
	var a := progress * (0.5 / Constants.IDLE_INITIAL_DELAY)
	_canvas.visible = true
	_canvas.find_child(Constants.HEADER_NAME).modulate.a = a
	_canvas.find_child(Constants.FOOTER_NAME).modulate.a = a

# stop idle
# undo idle fade in
func stop_idle():
	_canvas.find_child(Constants.HEADER_NAME).modulate.a = 1.0
	_canvas.find_child(Constants.FOOTER_NAME).modulate.a = 1.0
	_canvas.visible = false

# dialogue management

# is speaking
# returns true if the menus open are dialogue menus
func is_speaking() -> bool:
	return _dialogue_box in _menu_stack

# start dialogue
# function which begins a dialogue interaction with the player
func start_dialogue(dialogue_lines : Array):
	_dialogue_queue = dialogue_lines.duplicate(true)
	open_menu(Menus.dialogue_box)
	_show_next_line()

# show next line
# progresses the dialogue forward by one line of text
func _show_next_line():
	# animation interrupt
	if _is_animating:
		_finish_line()
		return
	
	# end of all lines
	if _dialogue_queue.is_empty():
		_end_dialogue()
		return
	
	_current_line = _dialogue_queue.pop_front()
	_dialogue_box.find_child(Constants.DIALOGUE_BOX_TITLE_NAME).text = _current_line.name
	
	_buffer_string = ""
	_update_box()
	_is_animating = true
	_timer = 0.0
	_line_index = 0

# function for clearing out current line animation progress
func _finish_line():
	_buffer_string = _current_line.text
	_is_animating = false
	_update_box()
	_check_for_choices()

# adjusting visual element
func _update_box():
	_dialogue_box.find_child(Constants.DIALOGUE_BOX_DESCRIPTION_NAME).text = _buffer_string

# wrapping up dialogue reading
func _end_dialogue():
	_dialogue_box.visible = false
	_is_animating = false
	close_menus()
	_buffer_string = ""
	_timer = 0.0

# check for choices
# generates choice labels and options, but only if there are choices
func _check_for_choices():
	if not _current_line.choices.is_empty():
		for choice in _current_line.choices:
			_dialogue_box.create_option(choice)
		_dialogue_box.move_selector_to(0)
		_dialogue_box.toggle_selector()
		_dialogue_box.lock_movement(false, true)

# clear options
# once an option is chosen, the options menu should be emptied
func _clear_options():
	_dialogue_box.unset_choices()
	_dialogue_box.toggle_selector()
	_dialogue_box.lock_movement(true, true)
