extends Area2D

var player

func _on_FloorExit_body_entered(body):
	if body.is_in_group("Player"):
		player = body
		player.show_nextFloorScreen()
	pass
