# Emerald March
# 07-03-2025
# Brian Morris

extends Node

# Utilities
# A bundle of functions on math and language processing

class_name Utilities

# Bresenham Line
# finds every integer point along a line
static func bresenham_line(start : Vector2i, end : Vector2i) -> Array:
	var points = []
	var x0 = start.x
	var y0 = start.y
	var x1 = end.x
	var y1 = end.y
	var dx = abs(x1 - x0)
	var dy = -abs(y1 - y0)
	var sx
	if x0 < x1:
		sx = 1
	else:
		sx = -1
	var sy
	if y0 < y1:
		sy = 1
	else:
		sy = -1
	var err = dx + dy

	while true:
		points.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var e2 = 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy

	return points
