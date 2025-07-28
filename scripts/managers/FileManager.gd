# Emerald March
# 07-29-2025
# Brian Morris

extends Node

# File Manager
# handles retrieving and parsing JSON data

class_name FileManager

# get region
# returns data needed to build a region accessed from region ID
static func get_region(region_id : Region.RegionID = Region.DEFAULT_REGION) -> Dictionary:
	print(region_id)
	var region_map := {}
	region_map["ground_map"] = [
		"0001112223335566",
		"0001112423335566",
		"0001112423335566",
		"0001114444445566",
		"0001112224335566",
		"0001112224335566",
		"0001112444335566",
		"0001112223335566"
	]
	region_map["terrain_map"] = [
		"2102223335550000",
		"2102223035550000",
		"2111111111550000",
		"2105550000000000",
		"2104443330220000",
		"2104443330220000",
		"2104444000220000",
		"2104444222220000"
	]
	region_map["collision_map"] = [
		"0000000000000000",
		"0000000000000000",
		"0000000000000000",
		"0001110000000000",
		"0000000000000000",
		"0000000000000000",
		"0000000000000000",
		"0000000000000000"
	]
	region_map["locations"] = [
		{
			"key_string" : "region",
			"position" : Vector2i(1,0),
			"type" : Region.LocationType.unknown,
			"entrance_id" : 0
		},{
			"key_string" : "region",
			"position" : Vector2i(1,7),
			"type" : Region.LocationType.unknown,
			"entrance_id" : 1
		},{
			"key_string" : "town",
			"position" : Vector2i(9,2),
			"type" : Region.LocationType.town,
			"entrance_id" : 0
		}
	]
	region_map["entrances"] = {
		0 : Vector2i(1,0),
		1 : Vector2i(1,7)
	}
	return region_map
