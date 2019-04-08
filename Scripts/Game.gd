extends Node2D

const titleScreen_scene = preload("res://Scenes/TitleScreen.tscn")
const player_scene = preload("res://Scenes/Player/Player.tscn")
const level_scene = preload("res://Scenes/Level.tscn")

var player
var player_health
var floorLabel
onready var current_level
var current_floor = 0

export var num_normal_rooms = 5

export var room_increase_rate = 2

func _input(event):
	if Input.is_key_pressed(KEY_R):
		current_level.free()
		current_level = level_scene.instance()
		add_child(current_level)
	pass


func _ready():
	pass

func start_level_one():
	$TitleScreen.queue_free()
	current_level = level_scene.instance()
	add_child(current_level)
	current_level.get_node("Dungeoneer").build_level(num_normal_rooms)
	pass


func on_dungeon_building_done():
	var rooms = current_level.get_node("Rooms").get_children()
	
	for room in rooms:
		if room.is_start_room:
			player = player_scene.instance()
			current_level.get_node("ObjectTileMap").add_child(player)
			player.global_position = room.get_center_point()
			break
	
	floorLabel = player.get_node("Camera2D/UI/UpperRightContainer/FloorLabel")
	floorLabel.text = "DUNGEON %sF" % [current_floor]
	pass


func on_level_building_restart():
	current_level.name = "OldLevel"
	$OldLevel.queue_free()
	
	var new_level = level_scene.instance()
	call_deferred("add_child", new_level)
	new_level.name = "Level"
	pass


func proceed_to_next_floor():
	current_level.name = "OldLevel"
	#save player health
	player_health = current_level.get_node("ObjectTileMap/Player").health
	
	$OldLevel.queue_free()
	
	var new_level = level_scene.instance()
	new_level.name = "Level"
	add_child(new_level)
	current_level = new_level
	current_floor += 1
	
	# increase the number of rooms
	current_level.get_node("Dungeoneer").build_level(num_normal_rooms + current_floor * room_increase_rate)
	floorLabel.text = "DUNGEON %sF" % [current_floor]
	
	# increase the number or enemies
	current_level.get_node("Dungeoneer").min_enemy_num += current_floor * 3
	current_level.get_node("Dungeoneer").max_enemy_num += current_floor * 3
	
	pass


func quit_to_title_screen():
	current_level.queue_free()
#	get_tree().paused = false
	var titleScreen = titleScreen_scene.instance()
	add_child(titleScreen)
	pass