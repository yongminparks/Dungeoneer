extends KinematicBody2D

const bounceDirt_scene = preload("res://Scenes/Particles/bounceDirtParticle.tscn")

var damage = 1

var full_speed = 350
var speed = full_speed
var direction = Vector2()
var velocity = Vector2()

onready var player = get_node("../Player")
onready var camera = get_node("../Player/Camera2D")

func _ready():
	self.add_to_group("Ball")
	velocity = direction * speed
	pass

func _process(delta):
	
#	if self.position.distance_to(player.position) >= 4:
#		$HitBox/CollisionShape2D.disabled = false
#		$CollisionShape2D.disabled = false
	
	var collision = move_and_collide(direction * speed * delta)
	
	if collision:
		if collision.collider.is_in_group("HitBall") or collision.collider.is_in_group("Player"):
			pass
		else:
			if collision.collider.is_in_group("Enemy"):
				var enemy = collision.collider
				enemy.get_hit(damage)
				enemy.knockback_direction = (self.global_position - player.global_position).normalized()
				enemy.speed = 20
				camera.shake(0.2, 10, 8)
				pass

			direction = direction.bounce(collision.normal)
			
			var bounceDirt = bounceDirt_scene.instance()
			get_parent().add_child(bounceDirt)
			bounceDirt.position.x = collision.position.x
			bounceDirt.position.y = collision.position.y - 5
			
#			How to lerp: var now_value = lerp(from_value, to_value, weight)
	
	speed = lerp(speed, 0, 0.015)
	
	if is_attacking():
		$Particles2D.emitting = true
	else:
		$Particles2D.emitting = false
	pass

func is_attacking():
	if speed >= 150:
		return true
	else:
		return false


func _on_HitBox_area_exited(area):
	if area.is_in_group("PlayerHitBox"):
		$HitBox/CollisionShape2D.disabled = false
		$CollisionShape2D.disabled = false
	pass # replace with function body


func _on_HitBox_body_entered(body):
	if body.is_in_group("Enemy"):
		body.get_hit(damage)

	pass # replace with function body
