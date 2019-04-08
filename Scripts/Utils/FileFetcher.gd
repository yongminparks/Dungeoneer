extends Node

# to fetching files

func _ready():

	pass

#func instance_particles():
#	var particle_dir = "res://Scenes/Enemies/BoneWorrior/"
#	var file_list = list_files_in_directory(particle_dir)
#
#	var particle_scenes
#
#	for particle_file in file_list:
#		var new_particle_scene_dir = str(particle_dir) + str(particle_file)
#		var new_particle_scene = load(new_particle_scene_dir)
#		var new_particle = new_particle_scene.instance()
#		get_parent().get_node("WallTileMap").call_deferred("add_child", new_particle)
#	pass

func get_file_list_in_directory(path):
    var files = []
    var dir = Directory.new()
    dir.open(path)
    dir.list_dir_begin()

    while true:
        var file = dir.get_next()
        if file == "":
            break
        elif not file.begins_with("."):
            files.append(file)

    dir.list_dir_end()

    return files


func get_scenes_in_directory(path):
	var file_list = get_file_list_in_directory(path)
	var scene_list = []
	
	for file in file_list:
		var scene_path = str(path) + str(file)
		var scene = load(scene_path)
		scene_list.append(scene)
	
	return scene_list
	pass