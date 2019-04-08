extends Node2D

const layoutTileset = preload("res://Scenes/Tiles/Tilesets/DunGeonBlockTileset.tres")

var smoke_particle_scene = preload("res://Scenes/Particles/bounceDirtParticle.tscn")

# Door scenes
var lockedDoor_scene = preload("res://Scenes/Doors/LockedDoor.tscn")
var combatDoor_scene = preload("res://Scenes/Doors/CombatDoor.tscn")

const cell_size = 16
var door_tile_id = 2

# random room setting
export var min_room_size = 4 # minimum room size (by 2 tiles)
export var max_room_size = 10 # maximum room size (by 2 tiles)

# door setting for random room
const door_corner_distance = 4 # -1 in the room (if 4, it's actually 3 inside a room)

var room_size_by_2cells = Vector2() # by 2 tiles
var room_size_by_cell = Vector2()

var room_fullrect_size = Vector2()

var topleft_cell = Vector2(0, 0)
var bottomright_cell = Vector2(0, 0)

# door properties
#var num_doors
var door_cells = []
var connected_door_cells = []
var corridors = []
var is_start_room = false
var is_end_room = false

var is_locked = false
var connected_rooms = []
var pathable_rooms = [] #for doorlock pathfinding

#enum ROOM_TYPES {Normal, Boss, Shop, Trophy}

var room_type

var door_objects = []

func get_rand_int(from, to):
	randomize()
	
	return floor(rand_range(from, to + 1))
	pass


func _ready():

	pass

# creates random rectangle room properties and set tiles based on that RNG
func init_random_rect_room():
	$WallTileMap.cell_size = Vector2(cell_size, cell_size)
	$DoorTileMap.cell_size = Vector2(cell_size, cell_size)
	
	room_type = "Normal"
	
	
	# set random room size
	room_size_by_2cells.x = get_rand_int(min_room_size, max_room_size)
	room_size_by_2cells.y = get_rand_int(min_room_size, max_room_size)
	
	room_size_by_cell = room_size_by_2cells * 2
	
	# note: range() function doesn't include max integer e.g. range(3) is [0, 1, 2]
	
	# set wall and floor cells in WallTileMap
	for ycell in range(0, room_size_by_cell.y):
		for xcell in range(0, room_size_by_cell.x):
			if ycell == 0 or ycell == room_size_by_cell.y - 1:
				$WallTileMap.set_cell(xcell, ycell, 1)
			else:
				if xcell == 0 or xcell == room_size_by_cell.x - 1:
					$WallTileMap.set_cell(xcell, ycell, 1)
				else:
					$WallTileMap.set_cell(xcell, ycell, 0)
	
	# set door cells by rule: 
	var corner_cell_list = [Vector2(0, 0), Vector2(room_size_by_cell.x, 0), 
	Vector2(0, room_size_by_cell.y), room_size_by_cell]
	
	bottomright_cell = room_size_by_cell - Vector2(1, 1)
	
	$DoorTileMap.set_cell(0, door_corner_distance, door_tile_id) # top left corner
	$DoorTileMap.set_cell(door_corner_distance, 0, door_tile_id)
	
	$DoorTileMap.set_cell(bottomright_cell.x - door_corner_distance - 1, 0, door_tile_id)
	$DoorTileMap.set_cell(bottomright_cell.x, door_corner_distance, door_tile_id)
	
	$DoorTileMap.set_cell(0, bottomright_cell.y - door_corner_distance - 1, door_tile_id)
	$DoorTileMap.set_cell(door_corner_distance, bottomright_cell.y, door_tile_id)
	
	$DoorTileMap.set_cell(bottomright_cell.x - door_corner_distance - 1, bottomright_cell.y, 
		door_tile_id)
	$DoorTileMap.set_cell(bottomright_cell.x, bottomright_cell.y - door_corner_distance - 1, 
		door_tile_id)
		
	init_door_cells($DoorTileMap)
	pass


func init_normal_fixed_room_at(topleft):
	room_type = 'Normal'
	init_room_on_position(topleft)
	pass


func init_fixed_room():
	init_door_cells($DoorTileMap)


func init_room_on_position(topleft):
	$WallTileMap.cell_size = Vector2(cell_size, cell_size)
	$DoorTileMap.cell_size = Vector2(cell_size, cell_size)
	topleft_cell = topleft
	room_fullrect_size = $WallTileMap.get_used_rect().size
	bottomright_cell = room_fullrect_size - Vector2(2, 2)
	pass

func init_door_cells(doorTileMap):
	var old_door_cells = doorTileMap.get_used_cells_by_id(door_tile_id)
	for door_cell in old_door_cells:
		door_cells.append(door_cell + topleft_cell)
	
#	unconnected_door_cells = door_cells
	pass


#func set_room_type(str_room_type):
#	match str_room_type:
#		'Normal':
#			room_type = ROOM_TYPES.Normal
#		'Shop':
#			room_type = ROOM_TYPES.Shop
#		_:
#			print("Error:: Room type input not matching ::")
#
#	pass


func get_center_point():
	var rect = $WallTileMap.get_used_rect()
	var middle_point = rect.position + rect.size * 0.5
	return middle_point * cell_size + self.position
	pass


func get_unconnected_door_cells():

	var unconnected_door_cells = door_cells
	for door_cell in connected_door_cells:
		unconnected_door_cells.erase(door_cell)
		unconnected_door_cells.erase(door_cell)
	
	return unconnected_door_cells
	pass


func keylock_all_doors():
	for door_cell in connected_door_cells:
		var new_locked_door = lockedDoor_scene.instance()
		add_child(new_locked_door)
		#to fix offset
		var fixed_door_cell = Vector2(door_cell.x, door_cell.y)
		new_locked_door.position = get_node("WallTileMap").map_to_world(fixed_door_cell)
		new_locked_door.room = self
		door_objects.append(new_locked_door)
	pass

func unlock_all_keylocked_doors():
	for door in door_objects:
		door.queue_free()
		var new_smoke_particle = smoke_particle_scene.instance()
		new_smoke_particle.global_position = door.global_position + Vector2(8, 8)
		new_smoke_particle.scale *= 3
		get_parent().add_child(new_smoke_particle)
	pass

func closeCombatDoors():
	for door_cell in connected_door_cells:
		var new_combat_door = combatDoor_scene.instance()
		add_child(new_combat_door)
		new_combat_door.position = get_node("WallTileMap").map_to_world(door_cell)
	pass


func place_combat_trigger():
	# set the collision areas to recognize if the player is entered the room
	# on the door cell?
	
	pass
	
	
func spawn_enemies(enemie_scene, amount):
	
	pass