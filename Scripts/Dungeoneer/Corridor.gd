extends Node2D

var cell_size = 16

# random generation properties
export var min_length = 6
export var max_length = 12

# corridor properties
var length = 8
var start_cell = Vector2()
var end_cell = Vector2()

var start_door_cell = Vector2()
var end_door_cell = Vector2()

var start_room
var end_room
var is_bent = false

enum DIRECTIONS {LEFT, RIGHT, UP, DOWN}
var start_direction
var end_direction

func get_rand_int(from, to):
	randomize()
	return floor(rand_range(from, to + 1))
	pass


func _ready():
	$WallTileMap.cell_size = Vector2(cell_size, cell_size)
	pass


func init_corridor_from_door(door_cell, room):
	var tilemap = room.get_node("WallTileMap")
	
	# initialize random properties
	length = get_rand_int(min_length, max_length)
	
	# check which side of the door is empty, and decide corridor direction (-1 is empty cell)
	if tilemap.get_cell(door_cell.x - 1, door_cell.y) == -1:
		start_direction = DIRECTIONS.LEFT
	elif tilemap.get_cell(door_cell.x + 1, door_cell.y) == -1:
		start_direction = DIRECTIONS.RIGHT
	elif tilemap.get_cell(door_cell.x, door_cell.y - 1) == -1:
		start_direction = DIRECTIONS.UP
	elif tilemap.get_cell(door_cell.x, door_cell.y + 1) == -1:
		start_direction = DIRECTIONS.DOWN

	# apply the global position(cell) to door_cell
	door_cell = door_cell + room.topleft_cell
	
	var wall_1_cell = Vector2()
	var floor_1_cell = Vector2()
	var floor_2_cell = Vector2()
	var wall_2_cell = Vector2()
	for i in range(0, length):
		match start_direction:
			DIRECTIONS.LEFT:
				wall_1_cell = Vector2(door_cell.x - 1 - i, door_cell.y - 1)
				floor_1_cell = Vector2(door_cell.x - 1 - i, door_cell.y)
				floor_2_cell = Vector2(door_cell.x - 1 - i, door_cell.y + 1)
				wall_2_cell = Vector2(door_cell.x - 1 - i, door_cell.y + 2)
			DIRECTIONS.RIGHT:
				wall_1_cell = Vector2(door_cell.x + 1 + i, door_cell.y - 1)
				floor_1_cell = Vector2(door_cell.x + 1 + i, door_cell.y)
				floor_2_cell = Vector2(door_cell.x + 1 + i, door_cell.y + 1)
				wall_2_cell = Vector2(door_cell.x + 1 + i, door_cell.y + 2)
			DIRECTIONS.UP:
				wall_1_cell = Vector2(door_cell.x - 1, door_cell.y - 1 - i)
				floor_1_cell = Vector2(door_cell.x, door_cell.y - 1 - i)
				floor_2_cell = Vector2(door_cell.x + 1, door_cell.y - 1 - i)
				wall_2_cell = Vector2(door_cell.x + 2, door_cell.y - 1 - i)
			DIRECTIONS.DOWN:
				wall_1_cell = Vector2(door_cell.x - 1, door_cell.y + 1 + i)
				floor_1_cell = Vector2(door_cell.x, door_cell.y + 1 + i)
				floor_2_cell = Vector2(door_cell.x + 1, door_cell.y + 1 + i)
				wall_2_cell = Vector2(door_cell.x + 2, door_cell.y + 1 + i)
		
		$WallTileMap.set_cellv(wall_1_cell, 1)
		$WallTileMap.set_cellv(floor_1_cell, 0)
		#should be editied to make a 2-cells-wide corridor or maybe not
		$WallTileMap.set_cellv(floor_2_cell, 1)
#		$WallTileMap.set_cellv(wall_2_cell, 1)
		
		if i == 0:
			start_cell = floor_1_cell
		
		if i == length - 1:
			# last cell of floor_1(aligned to the door) line will be matched to new room
			end_cell = floor_1_cell
		
		if is_bent == false:
			end_direction = start_direction
		
	pass