extends CanvasLayer

onready var player = get_node("../../")
func _ready():
	set_process(false)
	$Cover.visible = false
	$VBoxContainer.visible = false
	pass

func _process(delta):
	# press z to restart
	if Input.is_action_just_pressed("ui_accept"):
		player.game.quit_to_title_screen()
		pass
	pass


func show_game_over():
	set_process(true)
	$Cover.visible = true
	$VBoxContainer.visible = true
	pass
