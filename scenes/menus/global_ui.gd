# Emerald March
# 07-29-2025
# Brian Morris

extends CanvasLayer

# Global UI
# handles calls to the global user interface

# node references
@onready var _quit_warning := $QuitWarning
@onready var _quit_label := $QuitWarning/ColorRect/VBoxContainer/QuitLabel
@onready var _header := $Header
@onready var _footer := $Footer
@onready var _tool_tip := $Header/ToolTipBox
@onready var _descriptions := $Footer/Descriptions
@onready var _pause_menu := $Viewport/PauseMenu
@onready var _dialogue_box := $Viewport/DialogueBox
@onready var _idle_popup := $Header/IdlePopup
@onready var _party_display := $Footer/PartyDisplay
@onready var _battle_screen := $Viewport/BattleScreen

# control variables
const _MIN_QUIT_OPACITY := 0.4 # the starting opacity for fade ins

# enable overlay
# turns on the UI overlay
func _enable_overlay():
	_header.visible = true
	_footer.visible = true
	_header.modulate.a = 1.0
	_footer.modulate.a = 1.0
	_party_display.visible = true
	_update_party_display()

# disable overlay
# return to a full active viewport
func _disable_overlay():
	_header.modulate.a = 1.0
	_footer.modulate.a = 1.0
	_header.visible = false
	_footer.visible = false
	_party_display.visible = false

# update party display
# gives information to the party display to provide accurate information
func _update_party_display():
	pass

# start idling
# begin fading in the idle menu
func start_idling():
	_enable_overlay()
	_header.modulate.a = 0.0
	_footer.modulate.a = 0.0
	_idle_popup.visible = true

# update idle fade
# animate a fading transition for the idle menu
func update_idle_fade(alpha : float):
	_header.modulate.a = alpha
	_footer.modulate.a = alpha

# end idling
# close the idle menu
func end_idling():
	_idle_popup.visible = false
	_disable_overlay()

# update quit warning
# animate the warning that the player will lose their progress
func update_quit_warning(progress : float, quit_delay : float):
	# ensure progress is 0 > t > 1
	var progress_amount = clampf(progress, 0.0, 1.0)
	
	# lerp quit warning alpha
	var alpha = lerp(_MIN_QUIT_OPACITY, 1.0, progress_amount)
	_quit_warning.get_child(0).modulate.a = alpha
	
	# update text
	var remaining_sec = quit_delay - (progress_amount * quit_delay)
	var string_formatter = { "time" : "%.2f" % remaining_sec}
	var quit_warning := "Quitting in {time}...".format(string_formatter)
	_quit_label.text = quit_warning

# close quit warning
# stop the quit warning from being visible
func close_quit_warning():
	_quit_warning.get_child(0).modulate.a = 0.0
	_quit_warning.visible = false

# open pause menu
# make visible the pause menu for gameplay and open root on pause menu
func open_pause_menu():
	_enable_overlay()
	_pause_menu.visible = true
	_pause_menu.open()

# close pause menu
# hide the pause menu again
func close_pause_menu():
	_disable_overlay()
	_pause_menu.close()
	_pause_menu.visible = false

# start dialogue
# give lines of dialogue to the dialogue box
func start_dialogue(lines : Array[Dialogue]):
	_enable_overlay()
	_dialogue_box.visible = true
	_dialogue_box.start_dialogue(lines)

# end dialogue
# hide the dialogue box and end dialouge
func end_dialogue():
	# escape redundant calls
	if not _dialogue_box.visible:
		return
	
	# don't close overlay if pause menu is also still up
	if not _pause_menu.visible:
		_disable_overlay()
	_dialogue_box.end_dialogue()
	_dialogue_box.visible = false

# set pause active
# changes to pause menu gameplay
func set_pause_active(to_active : bool = true):
	_pause_menu.set_active(to_active)

# set dialogue active
# changes to dialogue menu gameplay
func set_dialogue_active(to_active : bool = true):
	_dialogue_box.active = to_active

# open battle
# give battle manager appropriate data to build itself, disabling any pause otherwise
func open_battle(battle_data : Dictionary):
	_enable_overlay()
	_battle_screen.visible = true
	_battle_screen.set_up(battle_data)

# end battle
# hide battle screen
func end_battle():
	_battle_screen.erase()
	_battle_screen.visible = false
	_disable_overlay()

# set battle active
# toggles battle mode controls
func set_battle_active(to_active : bool = true):
	_battle_screen.set_active(to_active)

# toggle auto battle
# menu button use for battle scene
func toggle_auto_battle():
	_battle_screen.toggle_auto_battle()

# toggle scoping
# hide / shows menu for scope gameplay
func toggle_scoping():
	if _descriptions.visible:
		_disable_overlay()
	else:
		_enable_overlay()
	_descriptions.visible = not _descriptions.visible
	_tool_tip.visible = not _tool_tip.visible

# update scope title
# displays text for titling scoping resources
func update_scope_title(title : String = ""):
	_tool_tip.get_child(0).text = title

# read scope data
# displays the data from a scope of a resource
func read_scope_data(data : Dictionary = {}):
	var display = ""
	if data == {}:
		_descriptions.get_child(0).text = display
		return
	# data either contains ground and terrain or location
	for item in data.keys():
		if not display == "":
			display += "\n"
		display += str(item)
		display += " : "
		display += str(data[item])
	_descriptions.get_child(0).text = display
