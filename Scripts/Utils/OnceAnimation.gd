extends AnimatedSprite

func _ready():
	self.connect("animation_finished", self, "_on_animation_finished")
	self.play()
	pass

func _process(delta):

	pass


func _on_animation_finished():
	self.queue_free()
	pass
