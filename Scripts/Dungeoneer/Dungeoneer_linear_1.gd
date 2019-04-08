extends Node2D

onready var target_level = get_node("../")
onready var room_list = []
onready var corridor_list = []

var room_script = preload("res://Scripts/Dungeoneer/Room.gd")
var start_room_scene = preload("res://Scenes/Rooms/Level1/TwoVerticalBarRoom.tscn")
var dungeonMap_tileset = preload("res://Scenes/Tiles/Tilesets/DunGeonBlockTileset.tres")

var rectangleRoom_scene = preload("res://Scenes/Rooms/BaseRooms/RectangleRoom.tscn")
var corridor_scene = preload("res://Scenes/Rooms/Corridor.tscn")

# dungeon layout setting
const tile_size = 16
var num_random_room = 99
var num_rooms_until_exitroom = 20
const num_fixed_room = 1
const num_additional_branch = 4
const layout_tile_id_size = 3 # number of tile size

# random corridor setting
var min_corr_length = 2
var max_corr_length = 10
var corr_width = 2

var layoutTileMap
var scanTileMap

var start_room
var start_room_topleft = Vector2(0, 0)

# room list variables
var fixed_room_list = []
var rand_room_list = []
var normal_room_list = []

var current_origin_room
var current_built_door_cell

var level_rooms
var level_corridors

enum DIRECTIONS {LEFT, RIGHT, UP, DOWN}

# global variable for checking failure
var should_restart = false

func _input(event):
	
	# camera zoom
	if Input.is_key_pressed(KEY_1):
		$Camera2D.current = true
		$Camera2D.zoom = $Camera2D.zoom + Vector2(0.1, 0.1)
	if Input.is_key_pressed(KEY_2):
		$Camera2D.zoom = $Camera2D.zoom - Vector2(0.1, 0.1)


func get_rand_int(from, to):
	randomize()
	return floor(rand_range(from, to + 1))
	pass


func shuffleList(list):
    var shuffledList = []
    var indexList = range(list.size())
    for i in range(list.size()):
        randomize()
        var x = randi()%indexList.size()
        shuffledList.append(list[x])
#       indexList.remove(x) # exclude this code
        list.remove(x)
    return shuffledList


func _ready():
	randomize()
	layoutTileMap = target_level.get_node("LayoutTileMap")
	scanTileMap = target_level.get_node("ScanTileMap")
	
	level_rooms = target_level.get_node("Rooms")
#	corridors = target_level.get_node("Corridors")
	
	make_layout()
	
	var restart_limit = 9999

	while restart_limit > 0 and should_restart:
		print("here")
		print(restart_limit)
		make_layout()
		restart_limit -= 1
		layoutTileMap.clear()
		scanTileMap.clear()
	
	pass


func make_fixed_room_list(num):
	
	
	pass


func init_random_room_list(num):
	normal_room_list.clear()
	for i in range(0, num):
		var new_room = rectangleRoom_scene.instance()
		new_room.set_script(room_script)
		new_room.init_random_rect_room()
		
		rand_room_list.append(new_room)
		normal_room_list.append(new_room)
		pass
	pass


func make_layout():
	# spawn start room
	start_room = start_room_scene.instance()
	start_room.get_node("WallTileMap").set_visible(false)
	room_list.append(start_room)
	start_room.set_script(room_script)
	clone_tilemap_to_tilemap(start_room.get_node("WallTileMap"), target_level.get_node("LayoutTileMap"), 
		start_room_topleft)
	start_room.init_fixed_room_at(start_room_topleft)
	start_room.is_start_room = true
	level_rooms.add_child(start_room)
	
	init_random_room_list(num_random_room)
	
	connect_a_new_room(start_room, normal_room_list.front())
	current_origin_room = normal_room_list.pop_front()
	
	###### just putting rooms and corridors in the scanTileMap, !without overlap check!
	
	
	for i in range(0, num_rooms_until_exitroom - 1):
		
		connect_a_new_room(current_origin_room, normal_room_list.front())
		current_origin_room = normal_room_list.pop_front()
		
#		if should_restart:
#			return
		pass
	
	
	pass


func connect_a_new_room(origin_room, new_room):
	var is_overlapping = true
	print(origin_room, new_room)
	for door in origin_room.unconnected_door_cells:
		build_scantiles_to_check_overlaps(origin_room, new_room)
		is_overlapping = are_tilemaps_overlapping(scanTileMap, layoutTileMap)
		if is_overlapping:
			scanTileMap.clear()
		else:
			# passed the check, actually put the corridor and the room on layoutTileMap
			clone_tilemap_to_tilemap(scanTileMap, layoutTileMap, Vector2(0, 0))
			origin_room.unconnected_door_cells.remove(
				origin_room.unconnected_door_cells.find(current_built_door_cell))
			
			# put a new room under the "Rooms" node
#			level_rooms.add_child(new_room)
			new_room.position = new_room.position + new_room.get_node("WallTileMap").map_to_world(new_room.topleft_cell)
#			move_tiles_by_offset_vector(new_room.get_node("WallTileMap"), new_room.topleft_cell)
#			move_tiles_by_offset_vector(new_room.get_node("DoorTileMap"), new_room.topleft_cell)
			should_restart = false
			return
		pass
	
	# used all doors but still couldn't connect new room. flag fail, retry from the base
	should_restart = true
	
	pass


func build_scantiles_to_check_overlaps(origin_room, new_room):
	var new_corr = attach_new_corridor_to(origin_room)
	var end_cell = new_corr.end_cell
	var corr_end_dir = new_corr.end_direction
	
	var new_room_door_dir
	
	# decide the opened side of a new room based on the corridor's end direction
	match corr_end_dir % 2:
		0:
			new_room_door_dir = corr_end_dir + 1
		1:
			new_room_door_dir = corr_end_dir - 1
	
	var matching_dir_doors = []
	var new_room_wall_tilemap = new_room.get_node("WallTileMap")
	
	# select doors with matching direction with the corridor
	for door_cell in new_room.door_cells:
		var door_direction
		if new_room_wall_tilemap.get_cell(door_cell.x - 1, door_cell.y) == -1:
			door_direction = DIRECTIONS.LEFT
		elif new_room_wall_tilemap.get_cell(door_cell.x + 1, door_cell.y) == -1:
			door_direction = DIRECTIONS.RIGHT
		elif new_room_wall_tilemap.get_cell(door_cell.x, door_cell.y - 1) == -1:
			door_direction = DIRECTIONS.UP
		elif new_room_wall_tilemap.get_cell(door_cell.x, door_cell.y + 1) == -1:
			door_direction = DIRECTIONS.DOWN

		if door_direction == new_room_door_dir:
			matching_dir_doors.append(door_cell)
	
	var rand_index = get_rand_int(0, matching_dir_doors.size() - 1)
	var chosen_door_cell = matching_dir_doors[rand_index]
	
	# place the new room to match the chosen door cell and the end of the corridor
	var diff_door_and_corr = new_corr.end_cell - chosen_door_cell
	clone_tilemap_to_tilemap(new_room.get_node("WallTileMap"), scanTileMap, diff_door_and_corr)
	# also move the room OBJECT according to that match
	new_room.topleft_cell = diff_door_and_corr
	pass


func attach_new_corridor_to(room):
	# choose random "unconnected" door from a room and adapt the room position
	var rand_door_index = get_rand_int(0, room.unconnected_door_cells.size() - 1)
	
	var chosen_door_cell = room.unconnected_door_cells[rand_door_index]
	# to remove built door from the door
	current_built_door_cell = chosen_door_cell
	
	
	var stanTileMap = target_level.get_node("ScanTileMap")
	
	var new_corr = corridor_scene.instance()
	new_corr.init_corridor_from_door(chosen_door_cell, room)
	
	# put new corridor to the ScanTileMap
	clone_tilemap_to_tilemap(new_corr.get_node("WallTileMap"), target_level.get_node("ScanTileMap"), Vector2(0, 0))
	
	# NOTE: maybe I can track attatched corridors by each room
	
	room.corridors.append(new_corr)
	return new_corr
	pass


func clone_tilemap_to_tilemap(source, target, topleft_cell):
	for tile_id in range(layout_tile_id_size):
		var source_cells = source.get_used_cells_by_id(tile_id)
		for cell in source_cells:
			target.set_cellv(cell + topleft_cell, tile_id)
	pass


func move_tiles_by_offset_vector(tilemap, offset):
	var tempTileMap = TileMap.new()
	tempTileMap.set_tileset(dungeonMap_tileset)
	
	clone_tilemap_to_tilemap(tilemap, tempTileMap, Vector2(0, 0))
	tilemap.clear()
	clone_tilemap_to_tilemap(tempTileMap, tilemap, offset)
	tempTileMap.queue_free()
	pass


func are_tilemaps_overlapping(tilemap_S, tilemap_L):
	var tilemap_S_cells = tilemap_S.get_used_cells()
	var tilemap_L_cells = tilemap_L.get_used_cells()
	
	if tilemap_S_cells.empty() or tilemap_L_cells.empty():
		return true
	
	# loop with 'S'mall tilemap
	for cell_S in tilemap_S_cells:
		for cell_L in tilemap_L_cells:
			if cell_S == cell_L:
				# tilemaps do overlap
				return true
		pass
	
	return false
	pass