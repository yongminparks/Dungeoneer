extends StaticBody2D

var room

func _on_UnlockArea_body_entered(body):
	if body.is_in_group("Player"):
		if body.num_keys > 0:
			body.consume_a_key()
			room.unlock_all_keylocked_doors()
	pass # Replace with function body.
