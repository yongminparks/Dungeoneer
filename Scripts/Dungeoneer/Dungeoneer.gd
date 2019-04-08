extends Node2D

onready var target_level = get_node("../")
#onready var room_list = []
onready var corridor_list = []

var room_script = preload("res://Scripts/Dungeoneer/Room.gd")
var start_room_scene = preload("res://Scenes/Rooms/Level1/TwoVerticalBarRoom.tscn")
var dungeonMap_tileset = preload("res://Scenes/Tiles/Tilesets/DunGeonBlockTileset.tres")

var room_scene = preload("res://Scenes/Rooms/Room.tscn")
var rectangleRoogm_scene = preload("res://Scenes/Rooms/BaseRooms/RectangleRoom.tscn")
var corridor_scene = preload("res://Scenes/Rooms/Corridor.tscn")

var start_rooms_path = "res://Scenes/Rooms/SpecialRooms/StartRooms/"
var boss_rooms_path = "res://Scenes/Rooms/SpecialRooms/BossRooms/"
var shop_rooms_path = "res://Scenes/Rooms/SpecialRooms/ShopRooms/"
var reward_rooms_path = "res://Scenes/Rooms/SpecialRooms/RewardRooms/"

# tilesets
var crypt_tileset = preload("res://Scenes/Tiles/Tilesets/WallTilesets/CryptTileset1.tres")
var cave_tileset = preload("res://Scenes/Tiles/Tilesets/WallTilesets/CaveTileset1.tres")

export(String, "Crypt", "Cave") var tileset_theme = "Crypt"

# enemie scenes
var enemy_scenes_path = "res://Scenes/Enemies/"
var bone_worrior_scene = preload("res://Scenes/Enemies/BoneWorrior.tscn")
var hornedEyeball_scene = preload("res://Scenes/Enemies/HornedEyeBall.tscn")
# enemie number settings per each normal room
export var min_enemy_num = 3
export var max_enemy_num = 6

# dungeon object scenes
var floor_exit_ecene = preload("res://Scenes/Objects/FloorExit.tscn")
var key_scene = preload("res://Scenes/Resources/Key.tscn")

# dungeon layout setting
var tile_size = 16
var num_normal_rooms = 5 # number of normal rooms
# var num_rooms_until_exitroom = 10
const num_fixed_rooms = 1
const num_additional_branch = 4
const layout_tile_id_size = 3 # number of tile size

# random corridor setting
export var min_corr_length = 2
var max_corr_length = 10
var corr_width = 2

var layoutTileMap
var scanTileMap
var wallTileMap

var start_room
var start_room_topleft = Vector2(0, 0)

# room list variables
var fixed_room_list = []
var rand_room_list = []
var normal_room_list = []
var branchable_room_nodes = []

var current_origin_room
var current_origin_door_cell
var current_end_door_cell

var level_rooms
var level_corridors

enum DIRECTIONS {LEFT, RIGHT, UP, DOWN}

# global variable for checking failure
var should_restart = false


signal dungeon_building_done
signal level_building_restart

var pathfinding_list = [] # for doors and locks
var is_generating_exit_path = false

func build_level(room_number):
	num_normal_rooms = room_number
	
	# connect signal for dungeon building is done
	connect("dungeon_building_done", get_node("../../"), "on_dungeon_building_done")
	connect("level_building_restart", get_node("../../"), "on_level_building_restart")
	
	randomize()
	layoutTileMap = target_level.get_node("LayoutTileMap")
	scanTileMap = target_level.get_node("ScanTileMap")
	wallTileMap = target_level.get_node("WallTileMap")
	level_rooms = target_level.get_node("Rooms")
#	corridors = target_level.get_node("Corridors")
	
	make_layout()
	
	var restart_limit = 999

	# how can this loop and checking

	while restart_limit > 0 and should_restart:
		print("restart layout building")
		print(restart_limit)
		clean_current_layout_building()
		make_layout()
		restart_limit -= 1
	
	# layout building done
	emit_signal("dungeon_building_done")
	
	set_room_nodes_visibility(false)
	open_walls_for_doors()
	print("size: ", level_rooms.get_children().size())
	place_wall_tiles()
	
	spawn_enemies_in_normal_rooms()
	place_floor_exit()
	place_door_and_lock()
	pass


func _ready():
	pass


func get_rand_int(from, to):
	randomize()
	return floor(rand_range(from, to + 1))
	pass


func get_rand_element_from_list(list):
	randomize()
	var rand_index = get_rand_int(0, list.size() - 1)
	return list[rand_index]
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


func set_room_nodes_visibility(bin):
	#only disable tiles
	
	for room in level_rooms.get_children():
		room.get_node("WallTileMap").visible = bin
		room.get_node("DoorTileMap").visible = bin
	pass

func open_walls_for_doors():
	for room in level_rooms.get_children():
		var door_cells = room.connected_door_cells
		
		for door_cell in door_cells:
			door_cell = door_cell + room.topleft_cell
			var open_position = room.get_node("DoorTileMap").map_to_world(door_cell)
			var open_cell = layoutTileMap.world_to_map(open_position)
			layoutTileMap.set_cellv(open_cell, 0) # make it to the floor
	pass


func clean_current_layout_building():
	layoutTileMap.clear()
	scanTileMap.clear()
	normal_room_list.clear()
	branchable_room_nodes.clear()
	
	pathfinding_list.clear()
	is_generating_exit_path = false
	# free all rooms in the $Rooms tree
	for room in level_rooms.get_children():
		room.free()
	pass


func make_fixed_room_list(num):
	
	pass


func init_random_room_list(num):
	rand_room_list.clear()
	for i in range(0, num):
		var new_room = room_scene.instance()
#		new_room.set_script(room_script)
		new_room.init_random_rect_room()
		
		rand_room_list.append(new_room)
		normal_room_list.append(new_room)
		pass
	pass


func get_and_init_one_room_from_path(path):
	var room_list = $FileFetcher.get_scenes_in_directory(path)
	var room_scene = get_rand_element_from_list(room_list)
	
	var room = room_scene.instance()
	room.set_script(room_script)
	room.init_fixed_room()
	
	return room
	pass

func get_one_random_scene_from_path(path):
	var scene_list = $FileFetcher.get_scenes_in_directory(path)
	var scene = get_rand_element_from_list(scene_list)
	return scene
	pass


func make_layout():
	normal_room_list.clear()
#	spawn start room
#	start_room = start_room_scene.instance()
#	start_room.get_node("WallTileMap").set_visible(false)
#	room_list.append(start_room)
#	start_room.set_script(room_script)
	var start_room = get_and_init_one_room_from_path(start_rooms_path)
	
	clone_tilemap_to_tilemap(start_room.get_node("WallTileMap"), target_level.get_node("LayoutTileMap"), 
		start_room_topleft)
	start_room.is_start_room = true
	level_rooms.add_child(start_room)
	branchable_room_nodes.append(start_room)
	
	init_random_room_list(num_normal_rooms)
	print("normal room list size:", normal_room_list.size())
	current_origin_room = start_room
	
	
	# Boss room
	var boss_room = get_and_init_one_room_from_path(boss_rooms_path)
	# decide the distances until the boss room
	var num_rooms_until_exitroom = floor(num_normal_rooms * 0.7)
	var rand_offset = floor(num_normal_rooms / 8)
	num_rooms_until_exitroom = get_rand_int(num_rooms_until_exitroom - rand_offset, num_rooms_until_exitroom + rand_offset)
	is_generating_exit_path = true
	make_path_to_deadend(num_rooms_until_exitroom, current_origin_room)
	is_generating_exit_path = false
	if should_restart:
		return
	connect_a_new_room(current_origin_room, boss_room)
	if should_restart:
		return
	boss_room.is_end_room = true
	
	
	# Shop room
	var shop_room = get_and_init_one_room_from_path(shop_rooms_path)
	
	var length_to_deadend = get_rand_int(0, normal_room_list.size())
	var chosen_branchable_room = get_rand_element_from_list(branchable_room_nodes)
	make_path_to_deadend(length_to_deadend, chosen_branchable_room)
	if should_restart:
		return
	connect_a_new_room(current_origin_room, shop_room)
	if should_restart:
		return


	# Reward room (Trophy room)
	var reward_room = get_and_init_one_room_from_path(reward_rooms_path)
	length_to_deadend = get_rand_int(0, normal_room_list.size())
	chosen_branchable_room = get_rand_element_from_list(branchable_room_nodes)
	make_path_to_deadend(length_to_deadend, chosen_branchable_room)
	if should_restart:
		return
	connect_a_new_room(current_origin_room, reward_room)
	if should_restart:
		return

	# make paths to spend left rooms
	var tmp_count = 0
	while normal_room_list.empty() == false:
		print("normal room left: ", normal_room_list.size())
		length_to_deadend = get_rand_int(0, normal_room_list.size())
		chosen_branchable_room = get_rand_element_from_list(branchable_room_nodes)
		make_path_to_deadend(length_to_deadend, chosen_branchable_room)
		if should_restart:
			return
		tmp_count += 1
	
	pass


func make_path_to_deadend(path_length, origin_room):
	
	current_origin_room = origin_room
	
	for i in range(0, path_length):
		if i == path_length:
			# place the deadend room
			break
		else: # build a path
			print("build a room on path")
			connect_a_new_room(current_origin_room, normal_room_list.front())
			current_origin_room = normal_room_list.pop_front()
			branchable_room_nodes.append(current_origin_room)
		if should_restart:
			return
	pass


func connect_a_new_room(origin_room, new_room):
	should_restart = false
	var is_overlapping = true
	print(origin_room, new_room)
	for door in origin_room.get_unconnected_door_cells():
		build_scantiles_to_check_overlaps(origin_room, new_room)
		is_overlapping = are_tilemaps_overlapping(scanTileMap, layoutTileMap)
		if is_overlapping:
			scanTileMap.clear()
		else:
			# passed the check, actually put the corridor and the room on layoutTileMap
			clone_tilemap_to_tilemap(scanTileMap, layoutTileMap, Vector2(0, 0))
			origin_room.connected_door_cells.append(current_origin_door_cell)
			new_room.connected_door_cells.append(current_end_door_cell)
			# put a new room under the "Rooms" node
			level_rooms.add_child(new_room)
			new_room.position = new_room.position + new_room.get_node("WallTileMap").map_to_world(new_room.topleft_cell)
#			move_tiles_by_offset_vector(new_room.get_node("WallTileMap"), new_room.topleft_cell)
#			move_tiles_by_offset_vector(new_room.get_node("DoorTileMap"), new_room.topleft_cell)
			should_restart = false
			
			# two rooms save each other
			origin_room.connected_rooms.append(new_room)
			new_room.connected_rooms.append(origin_room)
			# record path to exit
			if is_generating_exit_path:
				pathfinding_list.append(new_room)
			
			return
		pass
	
	# used all doors but still couldn't connect new room. flag fail, retry from the base
	should_restart = true
	print("restart_flag")
#	emit_signal("level_building_restart")
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
	# move the room OBJECT according to that match
	new_room.topleft_cell = diff_door_and_corr
	# add end door to the connected door list of the new room
	current_end_door_cell = chosen_door_cell
	pass


func attach_new_corridor_to(room):
	# choose random "unconnected" door from a room and adapt the room position
	var rand_door_index = get_rand_int(0, room.get_unconnected_door_cells().size() - 1)
	
	var chosen_door_cell = room.get_unconnected_door_cells()[rand_door_index]
	# to remove built door from the door
	current_origin_door_cell = chosen_door_cell
	
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
	tempTileMap.call_deferred("queue_free")
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
	
# layout making end ---------------------------------------------------


# tile placement --------------------------------------------------------
func place_wall_tiles():
	# set tileset from exported option
	var wall_tileset
	match tileset_theme:
		"Crypt":
			wall_tileset = crypt_tileset
		"Cave":
			wall_tileset = cave_tileset
	
	wallTileMap.set_tileset(wall_tileset)
	target_level.get_node("FrontWallTileMap").set_tileset(wall_tileset)
	
	var wall_cells = layoutTileMap.get_used_cells_by_id(1)
	
	for wall_cell in wall_cells:
		var neighbor_cells = []
		# start appending from top left cell
		neighbor_cells.append(wall_cell + Vector2(-1, -1))
		neighbor_cells.append(wall_cell + Vector2(0, -1))
		neighbor_cells.append(wall_cell + Vector2(1, -1))
		neighbor_cells.append(wall_cell + Vector2(-1, 0))
		neighbor_cells.append(wall_cell + Vector2(1, 0))
		neighbor_cells.append(wall_cell + Vector2(-1, 1))
		neighbor_cells.append(wall_cell + Vector2(0, 1))
		neighbor_cells.append(wall_cell + Vector2(1, 1))
		
		# neighbor cell indexes, c is the chosen cell
		# 0 1 2
		# 3 c 4
		# 5 6 7
		
		var neighbor_cell_tiles = []
		
		for neighbor_tile in neighbor_cells:
			neighbor_cell_tiles.append(layoutTileMap.get_cellv(neighbor_tile))
		var neighbor_floors = []
		# find neighboring floor cells
		for i in range(0, neighbor_cell_tiles.size()):
			if neighbor_cell_tiles[i] == 0:
				neighbor_floors.append(i)
		if neighbor_floors.has(0) && neighbor_floors.has(1) && neighbor_floors.has(3):
			wallTileMap.set_cellv(wall_cell, 9) # top left outward tile
		elif neighbor_floors.has(1) && neighbor_floors.has(2) && neighbor_floors.has(4):
			wallTileMap.set_cellv(wall_cell, 11) # top right outward tile
		elif neighbor_floors.has(3) && neighbor_floors.has(5) && neighbor_floors.has(6):
			wallTileMap.set_cellv(wall_cell, 15) # bottom left outward tile
		elif neighbor_floors.has(4) && neighbor_floors.has(6) && neighbor_floors.has(7):
			wallTileMap.set_cellv(wall_cell, 17) # bottom right outward tile
		elif neighbor_cell_tiles.count(0) == 1: # if only one floor cell(id: 0) is near
			var floor_cell_index = neighbor_cell_tiles.find(0)
			if floor_cell_index == 0: # if topleft is floor
				wallTileMap.set_cellv(wall_cell, 8) # bottom right inward tile
			elif floor_cell_index == 2: # if topright is floor
				wallTileMap.set_cellv(wall_cell, 6) # bottom left inward tile
			elif floor_cell_index == 5: # if bottomleft is floor
				wallTileMap.set_cellv(wall_cell, 2) # top right inward tile
			elif floor_cell_index == 7: # if bottomright is floor
				wallTileMap.set_cellv(wall_cell, 0) # topleft inward tile
		else: # 4 side walls
			if neighbor_floors.has(1):
				wallTileMap.set_cellv(wall_cell, 7) # bottom inward tile
			elif neighbor_floors.has(3):
				wallTileMap.set_cellv(wall_cell, 5) # right inward tile
			elif neighbor_floors.has(4):
				wallTileMap.set_cellv(wall_cell, 3) # left inward tile
			elif neighbor_floors.has(6):
				wallTileMap.set_cellv(wall_cell, 1) # up inward tile
		pass
		
	place_frontWall_tiles()
	pass


func place_frontWall_tiles():
	var frontWallTileMap = target_level.get_node("FrontWallTileMap")
	
	var frontWall_tile_ids = [0, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 14]
	
	for tile_id in frontWall_tile_ids:
		var frontWall_cells = wallTileMap.get_used_cells_by_id(tile_id)
		for wall_cell in frontWall_cells:
			frontWallTileMap.set_cellv(wall_cell, tile_id)
	pass


func spawn_enemies_in_normal_rooms():
	# make enemy list
	var enemy_scenes = []
	enemy_scenes.append(bone_worrior_scene)
	enemy_scenes.append(hornedEyeball_scene)
	
	# enemy number settings are on the top
	var normal_rooms = []
	
	for room in target_level.get_node("Rooms").get_children():
		if room.room_type == "Normal":
			normal_rooms.append(room)
	
	for normal_room in normal_rooms:
		# decide number of enemies per room
		var num_of_enemies = get_rand_int(min_enemy_num, max_enemy_num)
		
		# set upper limit depends on the room size
		var room_floor_size = normal_room.get_node("WallTileMap").get_used_cells_by_id(0).size()
		var enemy_num_limit = room_floor_size/4
		
		if num_of_enemies >= enemy_num_limit:
			num_of_enemies = enemy_num_limit
		
		for i in range(0, num_of_enemies):
			# choose random enemy scene from the list
			var new_enemy = get_rand_element_from_list(enemy_scenes).instance()
			
			var spawn_cell_list = normal_room.get_node("WallTileMap").get_used_cells_by_id(0)
			var spawn_cell = get_rand_element_from_list(spawn_cell_list) + normal_room.topleft_cell
			new_enemy.global_position = wallTileMap.map_to_world(spawn_cell)
			target_level.get_node("ObjectTileMap").call_deferred("add_child", new_enemy)
	pass

func place_floor_exit():
	# getting end room
	var end_room
	for room in target_level.get_node("Rooms").get_children():
		if room.is_end_room:
			end_room = room
			break
	
	var floor_exit = floor_exit_ecene.instance()
	floor_exit.global_position = end_room.get_center_point()
	target_level.get_node("ObjectTileMap").add_child(floor_exit)
	pass

func make_pathfinding_list():
	var room_path = []
	var unpathed_room_list = [] # to save rooms for later path
	var current_room # currently pointed room
	
	var start_room
	
	for room in level_rooms.get_children():
		room.pathable_rooms = room.connected_rooms.duplicate()
		if room.is_start_room:
			start_room = room
	
	current_room = start_room
	
	while current_room.pathable_rooms.empty() == false:
		room_path.append(current_room)
		var next_room = current_room.pathable_rooms.front()
		current_room.pathable_rooms.pop_front()
		unpathed_room_list += current_room.pathable_rooms
		current_room = next_room

	while unpathed_room_list.empty() == false:
		current_room = unpathed_room_list.front()
		
		while current_room.pathable_rooms.empty() == false:
			room_path.append(current_room)
			var next_room = current_room.pathable_rooms.front()
			current_room.pathable_rooms.pop_front()
			unpathed_room_list += current_room.pathable_rooms
			current_room = next_room
	pass

func place_door_and_lock():
	if pathfinding_list.size() <= 2:
		return
	var min_locked_room_index = get_rand_int(round(pathfinding_list.size()/2), pathfinding_list.size() - 1)
	var locked_room_index = get_rand_int(min_locked_room_index, pathfinding_list.size() - 1)
	pathfinding_list[locked_room_index].keylock_all_doors()
	randomize()
	# pick a room earlier than locked room
	var key_spawn_room_index = get_rand_int(0, locked_room_index - 1)
	var key_spawn_room = pathfinding_list[key_spawn_room_index]
	
	var new_key = key_scene.instance()
	new_key.global_position = key_spawn_room.get_center_point()
	target_level.add_child(new_key)
	pass