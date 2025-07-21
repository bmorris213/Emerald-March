# Emerald March
# 07-22-2025
# Brian Morris

extends Node

# Region
# encapsulates a single map on the overworld the player can explore

class_name Region

# tile map layers
var _ground_layer
var _terrain_layer
var _collision_layer
var _location_layer
var tile_size := 16

# interactables by location
var _locations := {}

# Ground Data
enum GroundType {
	normal,
	hazardous,
	dangerous,
	lethal,
	shallow_water,
	deep_water,
	none
}
const _GROUND_ATLAS_COORDS := {
	Vector2i(0,1): GroundType.normal,
	Vector2i(0,2): GroundType.hazardous,
	Vector2i(0,3): GroundType.dangerous,
	Vector2i(0,4): GroundType.lethal,
	Vector2i(5,2): GroundType.shallow_water,
	Vector2i(5,3): GroundType.deep_water
}
const _GROUND_DANGER_MULTIPLIERS := {
	GroundType.normal: 1.0,
	GroundType.hazardous: 1.2,
	GroundType.dangerous: 1.7,
	GroundType.lethal: 2.0,
	GroundType.shallow_water: 1.5
}

# Terrain Data
enum TerrainType {
	plains,
	roads,
	wilds,
	hills,
	woods,
	mountains
}
const _TERRAIN_ATLAS_COORDS := {
	Vector2i(1,1): TerrainType.wilds,
	Vector2i(1,2): TerrainType.hills,
	Vector2i(1,3): TerrainType.woods,
	Vector2i(1,4): TerrainType.mountains
}
const _TERRAIN_MOVE_SPEEDS := {
	TerrainType.plains : 2.4,
	TerrainType.roads : 2.9,
	TerrainType.wilds : 2.0,
	TerrainType.hills : 1.6,
	TerrainType.woods : 1.6,
	TerrainType.mountains : 1.2
}
const _TERRAIN_ENCOUNTER_RATES := {
	TerrainType.plains : 0.03,
	TerrainType.roads : 0.01,
	TerrainType.wilds : 0.06,
	TerrainType.hills : 0.07,
	TerrainType.woods : 0.08,
	TerrainType.mountains : 0.12
}

# init
# constructor
func _init(_root : Node):
	self._ground_layer = _root.find_child("GroundLayer")
	self._terrain_layer = _root.find_child("TerrainLayer")
	self._collision_layer = _root.find_child("CollisionLayer")
	self._location_layer = _root.find_child("LocationLayer")
	tile_size = _ground_layer.tile_set.tile_size.x

# set up region
# builds out a region map from data
func set_up_region(data : Array):
	for location in data:
		_locations[location.position] = location

# get speed
# retrieves the tile movement speed from location details in terms of tiles per second
func get_speed(pos : Vector2) -> float:
	return tile_size * _TERRAIN_MOVE_SPEEDS[get_terrain(pos)]

# get terrain
# retrieves the terrain data from a specific location
func get_terrain(pos : Vector2) -> TerrainType:
	var grid_pos = _terrain_layer.local_to_map(pos)
	var terrain = _terrain_layer.get_cell_atlas_coords(grid_pos)
	
	if terrain == Vector2i(-1, -1):
		return TerrainType.plains
	elif terrain.x < 5 and terrain.x > 1 and terrain.y > 0:
		return TerrainType.roads
	elif not _TERRAIN_ATLAS_COORDS.has(terrain):
		return TerrainType.plains
	else:
		return _TERRAIN_ATLAS_COORDS[terrain]

# get ground
# retrieves the ground data from a specific location
func get_ground(pos : Vector2) -> GroundType:
	var grid_pos = _ground_layer.local_to_map(pos)
	var ground = _ground_layer.get_cell_atlas_coords(grid_pos)
	
	if ground == Vector2i(-1, -1) or not _GROUND_ATLAS_COORDS.has(ground):
		return GroundType.none
	else:
		return _GROUND_ATLAS_COORDS[ground]

# has collision
# returns true if there is a tile at a specific location on the collision layer
func has_collision(pos : Vector2) -> bool:
	var grid_pos = _collision_layer.local_to_map(pos)
	var collision = _collision_layer.get_cell_atlas_coords(grid_pos)
	return collision != Vector2i(-1,-1)

# get interactable
# returns the interactable at a location, and an empty interactable if there is none
func get_interactable(pos : Vector2) -> Interactable:
	var grid_pos = _location_layer.local_to_map(pos)
	
	if grid_pos in _locations:
		return _locations[grid_pos]
	else:
		return Interactable.new()

# get encounter chance
# returns the chance for combat on a target location as a percentage
func get_encounter_chance(pos : Vector2) -> float:
	var ground = get_ground(pos)
	var terrain = get_terrain(pos)
	
	var ground_danger = _GROUND_DANGER_MULTIPLIERS[ground]
	var encounter_rate = _TERRAIN_ENCOUNTER_RATES[terrain]
	
	return encounter_rate * ground_danger

# get battle data
# returns the data relavant to starting a battle on a location
func get_battle_data(pos : Vector2) -> Dictionary:
	var ground = get_ground(pos)
	var terrain = get_terrain(pos)
	var collision = has_collision(pos)
	var interactable = get_interactable(pos) # WIP
	
	return {
		"ground" : ground,
		"terrain" : terrain,
		"collision" : collision,
		"interactable" : interactable
	}
