extends Area2D

var player

func _on_Key_body_entered(body):
	if body.is_in_group("Player"):
		player = body
		player.obtain_a_key()
		self.queue_free()
	pass
