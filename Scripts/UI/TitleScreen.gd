extends Node2D

onready var game = get_node("../")

func _ready():
	pass # Replace with function body.

func _process(delta):
	# press x to start
	if Input.is_action_just_pressed("ui_accept"):
		game.start_level_one()
		pass
	pass