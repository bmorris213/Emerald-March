# Emerald March
# 07-07-2025
# Brian Morris

extends Node

# Control Manager
# from the main scene, handles all user input in the game

class_name ControlManager

# control variables
var _input_locked := false
var _quit_timer := 0.0
var _trying_to_quit := false
var _idle_timer := 0.0

# menu control details
var _menu_direction := Vector2i.ZERO
var _menu_timer := 0.0
var _menu_delay := Constants.MENU_MAX_MAX_DELAY

# active control details
var _last_direction := Vector2i.ZERO
var _action_buffer := ""
var _move_buffer := Vector2i.ZERO
var _player_is_moving := false
var _quick_key_active := false
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

# handle input
# main control delegation loop
func handle_input(delta : float):
	# quick check for no longer being idle
	if _idle_timer != 0.0 and Input.is_anything_pressed():
		_idle_timer = 0.0
		GameManager.menu_manager.stop_idle()
	
	# accommodate input lock
	if _input_locked:
		return
	
	# check for quit action start and end
	if _trying_to_quit:
		if not Input.is_action_pressed("quit"):
			_trying_to_quit = false
			GameManager.menu_manager.signal_quitting(-1.0)
			_quit_timer = 0.0
	elif Input.is_action_pressed("quit"):
		_trying_to_quit = true
		_quit_timer = 0.0
	
	# delegate to quick key menu
	if _quick_key_active:
		# check for locking / unlocking
		if _quick_key_lock:
			if Input.is_action_pressed("cancel"):
				_quick_key_lock = false
		else:
			if Input.is_action_just_released("cancel"):
				_quick_key_active = false
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
			_quick_key_active = false
			_quick_key_lock = false
		return
	
	# delegate to menu controls
	if GameManager.menu_manager.viewing_menu():
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
		return
	
	# while in active control mode, cancel opens the quick menu
	if Input.is_action_just_pressed("cancel"):
		interrupt()
		_quick_key_active = true
		_quick_key_lock = true
		GameManager.menu_manager.open_menu(MenuManager.Menus.quick_menu)
		return
	
	# buffer actions and movement until movement ends
	if _player_is_moving:
		if Input.is_action_just_pressed("select"):
			_action_buffer = "select"
		elif Input.is_action_just_pressed("menu"):
			_action_buffer = "menu"
		if Input.is_action_just_pressed("up") and _last_direction != Vector2i.UP:
			_move_buffer = Vector2i.UP
		if Input.is_action_just_pressed("down") and _last_direction != Vector2i.DOWN:
			_move_buffer = Vector2i.DOWN
		if Input.is_action_just_pressed("left") and _last_direction != Vector2i.LEFT:
			_move_buffer = Vector2i.LEFT
		if Input.is_action_just_pressed("right") and _last_direction != Vector2i.RIGHT:
			_move_buffer = Vector2i.RIGHT
		return
	
	# check for a stored action buffer
	if _action_buffer != "":
		match(_action_buffer):
			"select":
				GameManager.scene_manager.try_select()
				_action_buffer = ""
				return
			"menu":
				GameManager.menu_manager.open_menu(MenuManager.Menus.pause_menu)
				return
	# check for a stored movement buffer
	if _move_buffer == Vector2i.UP and _last_direction != Vector2i.UP:
		_move_buffer = Vector2i.ZERO
		_last_direction = Vector2i.UP
		_player_is_moving = GameManager.scene_manager.move_player(_last_direction)
		return
	elif _move_buffer == Vector2i.DOWN and _last_direction != Vector2i.DOWN:
		_move_buffer = Vector2i.ZERO
		_last_direction = Vector2i.DOWN
		_player_is_moving = GameManager.scene_manager.move_player(_last_direction)
		return
	elif _move_buffer == Vector2i.LEFT and _last_direction != Vector2i.LEFT:
		_move_buffer = Vector2i.ZERO
		_last_direction = Vector2i.LEFT
		_player_is_moving = GameManager.scene_manager.move_player(_last_direction)
		return
	elif _move_buffer == Vector2i.RIGHT and _last_direction != Vector2i.RIGHT:
		_move_buffer = Vector2i.ZERO
		_last_direction = Vector2i.RIGHT
		_player_is_moving = GameManager.scene_manager.move_player(_last_direction)
		return
	
	# start a move or an action
	if Input.is_action_just_pressed("select"):
		GameManager.scene_manager.try_select()
	elif Input.is_action_just_pressed("menu"):
		GameManager.menu_manager.open_menu(MenuManager.Menus.pause_menu)
	elif Input.is_action_just_pressed("up"):
		_last_direction = Vector2i.UP
		_player_is_moving = GameManager.scene_manager.move_player(_last_direction)
	elif Input.is_action_just_pressed("down"):
		_last_direction = Vector2i.DOWN
		_player_is_moving = GameManager.scene_manager.move_player(_last_direction)
	elif Input.is_action_just_pressed("left"):
		_last_direction = Vector2i.LEFT
		_player_is_moving = GameManager.scene_manager.move_player(_last_direction)
	elif Input.is_action_just_pressed("right"):
		_last_direction = Vector2i.RIGHT
		_player_is_moving = GameManager.scene_manager.move_player(_last_direction)
	
	# active screen idle timer
	if not Input.is_anything_pressed():
		_idle_timer += delta
		
		if _idle_timer >= Constants.IDLE_INITIAL_DELAY and _idle_timer <= Constants.IDLE_INITIAL_DELAY * 3:
			GameManager.menu_manager.fade_in_idle(_idle_timer - Constants.IDLE_INITIAL_DELAY)

# will continue move
# called once the mover stops at a new tile
func will_continue_move() -> bool:
	# opening a menu stops movement
	if GameManager.menu_manager.viewing_menu():
		_move_buffer = Vector2i.ZERO
		_player_is_moving = false
		return false
	
	# we will only continue if the directional key is being held down
	if (Input.is_action_pressed("up") and _last_direction == Vector2i.UP) or\
	(Input.is_action_pressed("down") and _last_direction == Vector2i.DOWN) or\
	(Input.is_action_pressed("left") and _last_direction == Vector2i.LEFT) or\
	(Input.is_action_pressed("right") and _last_direction == Vector2i.RIGHT):
		# clear buffers and move
		_action_buffer = ""
		_move_buffer = Vector2i.ZERO
		_player_is_moving = GameManager.scene_manager.move_player(_last_direction)
		return true
	
	 # movement has ended
	_player_is_moving = false
	return false

# interrupt
# temporarily disables controls globally during a transition
func interrupt(duration : float = Constants.MIN_INTERRUPT_DURATION):
	# error check duration value
	if duration <= 0:
		push_error("ControlManager: interrupt called for <= 0 duration")
		return
	
	# enforce minimum and maximum durations
	if duration < Constants.MIN_INTERRUPT_DURATION:
		duration = Constants.MIN_INTERRUPT_DURATION
	elif duration > Constants.MAX_INTERRUPT_DURATION:
		duration = Constants.MAX_INTERRUPT_DURATION
	
	# disable controls
	_input_locked = true
	
	# wait the specified duration
	await GameManager.get_tree().create_timer(duration).timeout
	
	# re-enable controls globally after a transition
	_input_locked = false

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
