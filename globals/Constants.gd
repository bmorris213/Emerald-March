# Emerald March
# 07-22-2025
# Brian Morris

# Constants
# stores global constant variables for use, change, and project management

class_name Constants

# game management
const RNG_SEED := "test"

# scene references
enum SCENE_ID {
	main_menu,
	overworld,
	battle,
	location,
	dungeon,
	control_manager,
	file_manager,
	menu_manager,
	scene_manager,
	audio_manager
}
const SCENES := {
	SCENE_ID.main_menu: "res://scenes/menus/main_menu.tscn",
	SCENE_ID.overworld: "res://scenes/overworld/overworld.tscn",
	SCENE_ID.battle: "res://scenes/battle/battle.tscn",
	SCENE_ID.location: "res://scenes/location/location.tscn",
	SCENE_ID.dungeon: "res://scenes/dungeon/dungeon.tscn",
	SCENE_ID.control_manager: "res://scripts/managers/ControlManager.gd",
	SCENE_ID.file_manager: "res://scripts/managers/FileManager.gd",
	SCENE_ID.menu_manager: "res://scripts/managers/MenuManager.gd",
	SCENE_ID.scene_manager: "res://scripts/managers/SceneManager.gd",
	SCENE_ID.audio_manager: "res://scripts/managers/AudioManager.gd"
}
const INITIAL_SCENE := SCENES[SCENE_ID.overworld] # WIP replace with main menu

# scene node references
const PLAYER_NODE_PATH := "/Player"
const TILES_NODE_PATH := "/Ground Layer"
const OVERWORLD_EMPTY_TILE := Interactable.TILESET_INTERACTABLE_SPRITES[Interactable.INTERACT_TYPES.empty]

# overworld generation
enum REGIONS {
	Cel,
	Höf,
	Caelor,
	Eldefer,
	Thorazar,
	Moor,
	Missora,
	Indras,
	Alazar,
	Tarak,
	Dagohmor,
	Silvora,
	Telrasi,
	Mokhora,
	Poemas,
	Kililao
}
