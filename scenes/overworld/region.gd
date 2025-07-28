# Emerald March
# 07-29-2025
# Brian Morris

extends Resource

# Region
# encapsulates a single map on the overworld the player can explore

class_name Region

# every region in the game based on ID
enum RegionID {
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
const DEFAULT_REGION := RegionID.Cel

# maps of the region
var _ground_layer : Dictionary
var _terrain_layer : Dictionary
var _collision_layer : Dictionary
var _locations : Dictionary
var _map_size : Vector2i

var player_location : Vector2i
var _starting_location : Vector2i

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
const _GROUND_DANGER_MULTIPLIERS := {
	GroundType.normal: 1.0,
	GroundType.hazardous: 1.2,
	GroundType.dangerous: 1.7,
	GroundType.lethal: 2.0,
	GroundType.shallow_water: 1.5
}
const _GROUND_ATLAS_COORDS := {
	GroundType.normal: Vector2i(0,1),
	GroundType.hazardous: Vector2i(0,2),
	GroundType.dangerous: Vector2i(0,3),
	GroundType.lethal: Vector2i(0,4),
	GroundType.shallow_water: Vector2i(5,2),
	GroundType.deep_water: Vector2i(5,3)
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
const _TERRAIN_MOVE_SPEEDS := {
	TerrainType.plains : 2.8,
	TerrainType.roads : 3.2,
	TerrainType.wilds : 2.4,
	TerrainType.hills : 2.1,
	TerrainType.woods : 2.1,
	TerrainType.mountains : 1.8
}
const _TERRAIN_ENCOUNTER_RATES := {
	TerrainType.plains : 0.03,
	TerrainType.roads : 0.01,
	TerrainType.wilds : 0.06,
	TerrainType.hills : 0.07,
	TerrainType.woods : 0.08,
	TerrainType.mountains : 0.12
}
const _TERRAIN_ATLAS_COORDS := {
	TerrainType.plains: _EMPTY_ATLAS_COORDS,
	TerrainType.wilds: Vector2i(1,1),
	TerrainType.hills: Vector2i(1,2),
	TerrainType.woods: Vector2i(1,3),
	TerrainType.mountains: Vector2i(1,4)
}
const _EMPTY_ATLAS_COORDS := Vector2i(5, 1)

# collision data
const _COLLISION_ATLAS_COORDS := {
	true: Vector2i(0,0),
	false: _EMPTY_ATLAS_COORDS
}

# constructor
func _init(ground_map : Array, terrain_map : Array\
, collision_map : Array, locations : Array):
	var map_y_size : int = max(
		max(
			ground_map.size(), terrain_map.size()
		), collision_map.size()
	)
	var map_x_size : int = max(
		max(
			ground_map[0].length(), terrain_map[0].length()
		), collision_map[0].length()
	)
	_map_size = Vector2i(map_x_size, map_y_size)
	
	self._ground_layer = _get_layer(ground_map, func(arg):
		var int_arg : int = arg.to_int()
		return int_arg as GroundType
		)
	self._terrain_layer = _get_layer(terrain_map, func(arg):
		var int_arg : int = arg.to_int()
		return int_arg as TerrainType
		)
	self._collision_layer = _get_layer(collision_map, func(arg):
		return arg == "1"
		)
	for location in locations:
		self._locations[location.position] = location
	
	_starting_location = Vector2i(0,0)
	player_location = _starting_location

# get layer
# returns the layer of cells as a dictionary of vector2i -> data
func _get_layer(layer_map : Array, conversion_function : Callable) -> Dictionary:
	var layer := {}
	for i in layer_map.size():
		for j in layer_map[i].length():
			var cell = conversion_function.call(layer_map[i][j])
			layer[Vector2i(j, i)] = cell
	return layer

# get cell
# returns atlas coords for a single cell of the map
func _get_cell(map_layer : String, grid_pos : Vector2i):
	# for each layer, retrieve appropriate atlas coords
	match map_layer:
		"ground":
			if grid_pos in _ground_layer:
				var cell = _ground_layer[grid_pos] as GroundType
				return _GROUND_ATLAS_COORDS[cell]
			else:
				return _EMPTY_ATLAS_COORDS
		"terrain":
			if grid_pos in _terrain_layer:
				var cell = _terrain_layer[grid_pos] as TerrainType
				return _TERRAIN_ATLAS_COORDS[cell]
			else:
				return _EMPTY_ATLAS_COORDS
		"collision":
			if grid_pos in _collision_layer:
				var cell = _collision_layer[grid_pos] as bool
				return _COLLISION_ATLAS_COORDS[cell]
			else:
				return _EMPTY_ATLAS_COORDS
		"location":
			if grid_pos in _locations:
				return _locations[grid_pos].atlas_coords
			else:
				return _EMPTY_ATLAS_COORDS

# get speed
# retrieves the tile movement speed from location details in terms of tiles per second
func get_speed(grid_pos : Vector2i) -> float:
	return _TERRAIN_MOVE_SPEEDS[get_terrain(grid_pos)]

# get terrain
# retrieves the terrain data from a specific location
func get_terrain(grid_pos : Vector2i) -> TerrainType:
	if not _ground_layer:
		return TerrainType.plains
	if grid_pos in _terrain_layer:
		return _terrain_layer[grid_pos]
	return TerrainType.plains

# get ground
# retrieves the ground data from a specific location
func get_ground(grid_pos : Vector2i) -> GroundType:
	if not _ground_layer:
		return GroundType.none
	if grid_pos in _ground_layer:
		return _ground_layer[grid_pos]
	return GroundType.none

# has collision
# returns true if there is a tile at a specific location on the collision layer
func has_collision(grid_pos : Vector2i) -> bool:
	if not _collision_layer:
		return false
	if grid_pos in _collision_layer:
		return _collision_layer[grid_pos]
	return false

# get location
# returns the data, if any, stored for locations at a specific location
func get_location(grid_pos : Vector2i) -> Dictionary:
	if not _locations:
		return {}
	if grid_pos in _locations:
		return _locations[grid_pos]
	return {}

# search tile
# returns tile details resulting from a search
func search_tile(grid_pos : Vector2i) -> Dictionary:
	var ground = get_ground(grid_pos)
	var terrain = get_terrain(grid_pos)
	
	return { "ground": ground, "terrain": terrain }

# get encounter chance
# returns the chance for combat on a target location as a percentage
func get_encounter_chance(grid_pos : Vector2i) -> float:
	var ground : GroundType = get_ground(grid_pos)
	var terrain : TerrainType = get_terrain(grid_pos)
	
	var ground_danger = _GROUND_DANGER_MULTIPLIERS[ground]
	var encounter_rate = _TERRAIN_ENCOUNTER_RATES[terrain]
	
	return encounter_rate * ground_danger

# get data
# returns all data at the target position
func get_data(grid_pos : Vector2i) -> Dictionary:
	var ground = get_ground(grid_pos)
	var terrain = get_terrain(grid_pos)
	var collision = has_collision(grid_pos)
	var location = get_location(grid_pos)
	return {
		"ground" : ground,
		"terrain" : terrain,
		"collision" : collision,
		"location": location
	}

# is within borders
# returns true if the position is within the outer limits of the map
func is_within_border(grid_pos : Vector2i) -> bool:
	return grid_pos.x >= 0 and\
	grid_pos.y >= 0 and\
	grid_pos.x <= _map_size.x and\
	grid_pos.y <= _map_size.y

# get atlas_map
# returns a map of atlas coordinates per tile for each layer
func get_atlas_map(map_layer : String) -> Array:
	var map := []
	
	for i in _map_size.y:
		map.append([])
		for j in _map_size.x:
			var grid_pos := Vector2i(j, i)
			map[i].append(_get_cell(map_layer, grid_pos))
	
	return map
