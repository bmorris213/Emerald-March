# Emerald March
# 07-22-2025
# Brian Morris

extends Node

# Menu Tree
# encapsulates a branching tree of embedded menus
# and managing control activity between menus

class_name MenuTree

# control variables
var active : bool = false
@export var can_exit : bool = false # most trees, you can't close the scene

# node references
var _current_menu : Node = null
var _hide_current : bool = false
var _hide_current_selector : bool = false
@export var root_menu : NodePath
var _menu_stack : Array[Node] = []

# process
# runs once per frame
func _process(_delta):
	if _current_menu:
		_current_menu.active = active
	
	if not active:
		return
	
	if Input.is_action_just_pressed("cancel"):
		back()

# open
# starts new menu navigation, beginning at the root menu if none is given
func open(new_menu : NodePath = root_menu):
	if _current_menu:
		_current_menu.active = false
	var menu = get_node(new_menu)
	if menu:
		_menu_stack.push_back(menu)
		_current_menu = menu
		menu.active = true
		if not menu.visible:
			_hide_current = true
			menu.visible = true
		if not menu.selector_is_on():
			_hide_current_selector = true
			menu.toggle_selector()
		menu.toggle_selector()
		await get_tree().process_frame
		menu.move_selector_to(0)
		menu.toggle_selector()
	else:
		push_error("MenuTree: error menu node path in open")

# back
# navigates backward in the tree, potentially closing the menu
func back():
	if _menu_stack.size() <= 1:
		if can_exit:
			GameManager.pause()
		else:
			close()
		return
	
	# close current menu
	_current_menu.active = false
	if _hide_current_selector:
		_current_menu.toggle_selector()
	if _hide_current:
		_current_menu.visible = false
	_menu_stack.pop_back()
	
	# open previous menu
	_current_menu = _menu_stack[-1]
	_current_menu.active = true
	if not _current_menu.visible:
		_hide_current = true
		_current_menu.visible = true
	if not _current_menu.selector_is_on():
		_hide_current_selector = true
		_current_menu.toggle_selector()

# close
# exits menu navigation
func close():
	_current_menu.active = false
	if _hide_current_selector:
		_current_menu.toggle_selector()
	if _hide_current:
		_current_menu.visible = false
	
	if can_exit:
		_current_menu = null
		_menu_stack = []
	else:
		open() # return to root
