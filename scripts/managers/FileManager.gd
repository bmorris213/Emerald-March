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
		"1111111111111111",
		"1111111111111111",
		"1111111111111111",
		"1111111111111111",
		"1111111111111111",
		"1111111111111111",
		"1111111111111111",
		"1111111111111111"
	]
	region_map["terrain_map"] = [
		"0000000000000000",
		"0000000000000000",
		"0000000000000000",
		"0000000000000000",
		"0000000000000000",
		"0000000000000000",
		"0000000000000000",
		"0000000000000000"
	]
	region_map["collision_map"] = [
		"0000000000000000",
		"0000000000000000",
		"0000000000000000",
		"0000000000000000",
		"0000000000000000",
		"0000000000000000",
		"0000000000000000",
		"0000000000000000"
	]
	region_map["locations"] = []
	return region_map
