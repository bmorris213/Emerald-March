# Rise of the Dragon King
# 07-08-2025
# Brian Morris

extends Object

# Interactable
# represents some object in an active scene which can be interacted with in various ways

class_name Interactable

# types of interactions in the game
enum INTERACT_TYPES {
	point_of_interest,
	switch,
	container,
	entrance,
	npc,
	empty
}

# references to coordinates on the sprite atlas
const TILESET_INTERACTABLE_SPRITES := {
	INTERACT_TYPES.point_of_interest : Vector2i(2,0),
	INTERACT_TYPES.switch : Vector2i(2,1),
	INTERACT_TYPES.container : Vector2i(1,2),
	INTERACT_TYPES.entrance : Vector2i(1,1),
	INTERACT_TYPES.npc : Vector2i(2,2),
	INTERACT_TYPES.empty : Vector2i(0,2)
}

# variables for interaction
var position : Vector2i
var key_string : String
var description : String
var type : INTERACT_TYPES
var target_data : Dictionary
var hidden : bool
var temporary : bool

func _init(_pos : Vector2i = Vector2i.ZERO, _key : String = "", _description : String = "",\
	_type : INTERACT_TYPES = INTERACT_TYPES.empty, _target: Dictionary = {}, _hidden : bool = false, _temp : bool = false):
	self.position = _pos
	self.key_string = _key
	self.description = _description
	self.type = _type
	self.target_data = _target.duplicate(true)
	self.hidden = _hidden
	self.temporary = _temp
