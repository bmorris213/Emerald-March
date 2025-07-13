# Emerald March
# 07-13-2025
# Brian Morris

extends Node

# Control Manager
# from the main scene, handles all user input in the game

class_name ControlManager

# control mode
enum _mode {
	inactive,
	menu,
	quick_menu,
	scoping,
	overworld
}
var _control_mode := _mode.overworld

# control variables
var _quit_timer := 0.0
var _trying_to_quit := false
var _idle_timer := 0.0

# menu control details
var _menu_direction := Vector2i.ZERO
var _menu_timer := 0.0
var _menu_delay := Constants.MENU_MAX_MAX_DELAY
var _last_active_mode := _mode.overworld

# overworld control details
var _action_buffer := ""
var _player_is_moving := false

var _quick_key_lock := false # distinguish between a toggle and hold of quick key menu

# process
# called once per frame
func process(delta : float):
	# update acceleration information
	if _menu_direction != Vector2i.ZERO:
		_menu_timer += delta
		
		if _menu_timer >= _menu_delay:
			GameManager.menu_manager.move_selector(_menu_direction)
			_menu_timer = 0.0
			_menu_delay = max(Constants.MENU_MIN_DELAY, _menu_delay - Constants.MENU_ACCELERATION)
	
	# update quit timer
	if _trying_to_quit:
		# progress timer
		_quit_timer += delta
		GameManager.menu_manager.signal_quitting(_quit_timer / Constants.MENU_QUIT_DELAY)
		
		if _quit_timer >= Constants.MENU_QUIT_DELAY:
			GameManager.get_tree().quit() # exit game completely
	
	# overworld screen idle timer
	if _control_mode == _mode.overworld and not Input.is_anything_pressed():
		GameManager.scene_manager.is_idle = true
		_idle_timer += delta
		
		if _idle_timer >= Constants.IDLE_INITIAL_DELAY and _idle_timer <= Constants.IDLE_INITIAL_DELAY * 3:
			GameManager.menu_manager.fade_in_idle(_idle_timer - Constants.IDLE_INITIAL_DELAY)

# set menus
# changes to a menu input control
func set_menus():
	_last_active_mode = _control_mode
	_control_mode = _mode.menu

# return from menus
# returns from whence the menus arrived
func return_from_menus():
	_control_mode = _last_active_mode

# handle input
# main control delegation loop
func handle_input():
	# check for quit action start and end
	if _trying_to_quit:
		if not Input.is_action_pressed("quit"):
			_trying_to_quit = false
			GameManager.menu_manager.signal_quitting(-1.0)
			_quit_timer = 0.0
	elif Input.is_action_pressed("quit"):
		_trying_to_quit = true
		_quit_timer = 0.0
	
	# delegate to appropriate control mode
	match _control_mode:
		_mode.menu:
			_menu_input()
		_mode.quick_menu:
			_quick_input()
		_mode.scoping:
			_scope_input()
		_mode.overworld:
			_overworld_input()

# menu input
# handles processing input for any menus
func _menu_input():
	# speed while speaking
	if GameManager.menu_manager.is_speaking():
		if Input.is_action_pressed("cancel"):
			GameManager.menu_manager.rapid = true
		else:
			GameManager.menu_manager.rapid = false
	else:
		if Input.is_action_just_pressed("cancel"):
			GameManager.menu_manager.cancel()
			return
	
	if Input.is_action_just_pressed("select"):
		GameManager.menu_manager.select()
	elif Input.is_action_just_pressed("menu"):
		GameManager.menu_manager.close_menus()
	else:
		_handle_menu_movement()

# handle menu movement
# while the user is holding down a movement key, speed up selection calls
func _handle_menu_movement():
	# check for an end to selector movement
	match(_menu_direction):
		Vector2i.UP:
			if Input.is_action_just_released("up"):
				_end_menu_move()
		Vector2i.DOWN:
			if Input.is_action_just_released("down"):
				_end_menu_move()
		Vector2i.RIGHT:
			if Input.is_action_just_released("right"):
				_end_menu_move()
		Vector2i.LEFT:
			if Input.is_action_just_released("left"):
				_end_menu_move()
	
	# check if we're still moving but need to stop
	if _menu_direction != Vector2i.ZERO:
		if not Input.is_anything_pressed():
			_end_menu_move()
			return
	
	# check for the beginning of a new movement
	if Input.is_action_just_pressed("up"):
		_start_menu_move(Vector2i.UP)
	elif Input.is_action_just_pressed("down"):
		_start_menu_move(Vector2i.DOWN)
	elif Input.is_action_just_pressed("left"):
		_start_menu_move(Vector2i.LEFT)
	elif Input.is_action_just_pressed("right"):
		_start_menu_move(Vector2i.RIGHT)

# starts a movement of the selector for the menu
func _start_menu_move(new_direction : Vector2i):
	_menu_direction = new_direction
	GameManager.menu_manager.move_selector(_menu_direction)
	_menu_timer = 0.0
	_menu_delay = Constants.MENU_MAX_MAX_DELAY

# stops a movement of the selector for the menu
func _end_menu_move():
	_menu_direction = Vector2i.ZERO
	_menu_timer = 0.0
	_menu_delay = Constants.MENU_MAX_MAX_DELAY

# quick input
# handles processing input for the quick menu
func _quick_input():
	# check for locking / unlocking
	if _quick_key_lock:
		if Input.is_action_pressed("cancel"):
			_quick_key_lock = false
	else:
		if Input.is_action_just_released("cancel"):
			_control_mode = _mode.overworld
			GameManager.menu_manager.close_menus()
			return
	
	# update changing selection
	var quick_key_choice = Vector2i.ZERO
	if Input.is_action_pressed("up"):
		quick_key_choice = Vector2i.UP
	elif Input.is_action_pressed("down"):
		quick_key_choice = Vector2i.DOWN
	elif Input.is_action_pressed("left"):
		quick_key_choice = Vector2i.LEFT
	elif Input.is_action_pressed("right"):
		quick_key_choice = Vector2i.RIGHT
	GameManager.menu_manager.highlight_quick_key(quick_key_choice)
	
	# activate quick key option
	if Input.is_action_just_pressed("select"):
		var selected_action = GameManager.get_quick_action(quick_key_choice)
		GameManager.menu_manager.close_menus()
		GameManager.scene_manager.call_action(selected_action)
		_control_mode = _mode.overworld
		_quick_key_lock = false

# scope input
# handles processing input for the scoping mode
func _scope_input():
	# handle exiting scope
	if Input.is_action_just_pressed("menu"):
		GameManager.menu_manager.close_menus()
		GameManager.scene_manager.end_scoping()
		GameManager.menu_manager.open_menu(MenuManager.Menus.pause_menu)
		_control_mode = _mode.menu
		return
	if Input.is_action_just_pressed("cancel"):
		GameManager.menu_manager.close_menus()
		GameManager.scene_manager.end_scoping()
		return
	
	var direction = Vector2i.ZERO
	if Input.is_action_pressed("up"):
		direction.y = 1
	elif Input.is_action_pressed("down"):
		direction.y = -1
	if Input.is_action_pressed("right"):
		direction.x = 1
	elif Input.is_action_pressed("left"):
		direction.x = -1
	GameManager.scene_manager.move_scope(direction)

# overworld input
# handles processing input for the overworld mode
func _overworld_input():
	# quick check for no longer being idle
	if _idle_timer != 0.0 and Input.is_anything_pressed():
		_idle_timer = 0.0
		GameManager.menu_manager.stop_idle()
		GameManager.scene_manager.is_idle = false
	
	# buffer actions and movement until movement ends
	if _player_is_moving:
		if Input.is_action_just_pressed("select"):
			_action_buffer = "select"
		elif Input.is_action_just_pressed("menu"):
			_action_buffer = "menu"
		elif Input.is_action_just_pressed("cancel"):
			_action_buffer = "cancel"
		return
	
	# check for a stored action buffer
	if _action_buffer != "":
		match(_action_buffer):
			"select":
				GameManager.scene_manager.try_select()
				interrupt()
				return
			"menu":
				GameManager.menu_manager.open_menu(MenuManager.Menus.pause_menu)
				_control_mode = _mode.menu
				interrupt()
				return
			"cancel":
				if GameManager.scene_manager.is_in_overworld():
					_control_mode = _mode.scoping
					GameManager.scene_manager.start_scoping()
					GameManager.menu_manager.open_menu(MenuManager.Menus.scope_menu)
				else:
					_control_mode = _mode.quick_menu
					_quick_key_lock = true
					GameManager.menu_manager.open_menu(MenuManager.Menus.quick_menu)
				interrupt()
				return
			_:
				push_error("ControlManager: unknown action buffer!")
				return
	
	# start a move or an action
	if Input.is_action_just_pressed("select"):
		GameManager.scene_manager.try_select()
		interrupt()
	elif Input.is_action_just_pressed("menu"):
		GameManager.menu_manager.open_menu(MenuManager.Menus.pause_menu)
		_control_mode = _mode.menu
		interrupt()
	elif Input.is_action_just_pressed("cancel"):
		if GameManager.scene_manager.is_in_overworld():
			_control_mode = _mode.scoping
			GameManager.scene_manager.start_scoping()
			GameManager.menu_manager.open_menu(MenuManager.Menus.scope_menu)
		else:
			_control_mode = _mode.quick_menu
			_quick_key_lock = true
			GameManager.menu_manager.open_menu(MenuManager.Menus.quick_menu)
		interrupt()
	elif Input.is_action_pressed("up"):
		_player_is_moving = GameManager.scene_manager.move_player(Vector2i.UP)
	elif Input.is_action_pressed("down"):
		_player_is_moving = GameManager.scene_manager.move_player(Vector2i.DOWN)
	elif Input.is_action_pressed("left"):
		_player_is_moving = GameManager.scene_manager.move_player(Vector2i.LEFT)
	elif Input.is_action_pressed("right"):
		_player_is_moving = GameManager.scene_manager.move_player(Vector2i.RIGHT)

# move break
# tells controls player has stoped moving
func move_break():
	_player_is_moving = false

# interrupt
# temporarily disables controls globally during a transition
func interrupt(duration : float = Constants.MIN_INTERRUPT_DURATION):
	# error check duration value
	if duration <= 0:
		push_error("ControlManager: interrupt called for <= 0 duration")
		return
	
	_action_buffer = ""
	
	# enforce minimum and maximum durations
	if duration < Constants.MIN_INTERRUPT_DURATION:
		duration = Constants.MIN_INTERRUPT_DURATION
	elif duration > Constants.MAX_INTERRUPT_DURATION:
		duration = Constants.MAX_INTERRUPT_DURATION
	
	# disable controls
	var last_mode = _control_mode
	_control_mode = _mode.inactive
	
	# wait the specified duration
	await GameManager.get_tree().create_timer(duration).timeout
	
	# re-enable controls globally after a transition
	_control_mode = last_mode
