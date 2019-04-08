extends Area2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

const bulletSmoke_scene = preload("res://Scenes/Particles/BlueBulletSmokeParticle.tscn")

var speed = 80
var direction
var velocity

var damage = 1

func _ready():
	
	pass

func _process(delta):
	velocity = direction * speed
	set_position(get_position() + velocity * delta)


func _on_LongBullet_body_entered(body):
	if body.is_in_group("Wall"):
		var bulletSmoke = bulletSmoke_scene.instance()
		get_parent().add_child(bulletSmoke)
		bulletSmoke.position = self.position
		queue_free()
	if body.is_in_group("Player"):
			body.get_hit(damage)
			var bulletSmoke = bulletSmoke_scene.instance()
			get_parent().add_child(bulletSmoke)
			bulletSmoke.position = self.position
			queue_free()
			pass
	pass # replace with function body
