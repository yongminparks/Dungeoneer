extends Area2D

onready var player = get_node("../Player")
const ballHitSprite_scene = preload("res://Scenes/Player/Effect/BallHitSprite.tscn")

var speed = 5
var hit_time = 0.1;
onready var camera = get_node("../../Camera2D")

var direction = Vector2(0, 0)
var velocity

func _ready():
	self.add_to_group("HitBall")
	$KickSprite.play("default")
	velocity = direction * speed
	
	$HitTimer.set_wait_time(hit_time)
	$HitTimer.start()
	pass

func _process(delta):
	set_position(get_position() + velocity * delta)
	pass

func _on_KickSprite_animation_finished():
	self.queue_free()
	pass # replace with function body


func _on_KickProjectile_body_entered(body):
	if body.is_in_group("Ball"):
		# hit animation
		var hit_sprite = ballHitSprite_scene.instance()
		get_parent().add_child(hit_sprite)
		hit_sprite.global_position = body.global_position
		hit_sprite.rotation = (body.global_position - player.global_position).angle()
		camera.shake(0.2, 10, 8)
		
		# opt.1. relative direction
		var ball_direction = body.global_position - player.global_position
		# opt.2. 8 direction
#		var ball_direction = self.velocity.normalized()
		
		body.direction = ball_direction.normalized()
		body.speed = body.full_speed
		
		$CollisionShape2D.disabled = true
	pass
	


func _on_HitTimer_timeout():
	$CollisionShape2D.disabled = true
	pass # replace with function body
