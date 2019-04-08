extends "../Enemy.gd"

enum MODE {SEEK, READY, ATTACK, HURT}
var mode = MODE.SEEK

var velocity
var direction = Vector2()

const seek_speed = 50
var seek_change_min = 1
var seek_change_max = 2
const dash_speed = 350
var dash_time = 0.4

onready var detect_distance = 60

var targetNode
var target_distance
var target_direction

var ready_time = 0.7
var ready_to_attack = false
var is_readying = false

var speed

export var max_health_overwrite = 3

var knockback_speed = 50

func get_rand_range(from, to):
	randomize()
	return rand_range(from, to)

func get_vector_from_radian(radian):
	return Vector2(cos(radian), sin(radian))

func _ready():
	max_health = max_health_overwrite
	health = max_health
	
	damage = 0
	
	self.add_to_group("Enemy")
	targetNode = get_node("../Player")
	speed = seek_speed
	mode == MODE.SEEK
	var rand_degree = get_rand_range(0, 360)
	direction = get_vector_from_radian(rand_degree)
	start_to_seek()
	pass

func _process(delta):
	target_distance = global_position.distance_to(targetNode.global_position)
	target_direction = (targetNode.global_position - self.global_position).normalized()
	
	if mode == MODE.SEEK:
		$AnimatedSprite.play("run")
		speed = seek_speed
	elif mode == MODE.READY:
		$AnimatedSprite.play("ready")
		speed = 0
	elif mode == MODE.ATTACK:
		$AnimatedSprite.play("attack")
		speed = dash_speed
	elif mode == MODE.HURT:
		$AnimatedSprite.play("hurt")
		
	if target_distance <= detect_distance and mode == MODE.SEEK:
		$SeekChangeTimer.stop()
		mode = MODE.READY
		$ReadyTimer.set_wait_time(ready_time)
		$ReadyTimer.start()
		direction = target_direction
	if ready_to_attack and mode == MODE.READY:
		mode = MODE.ATTACK
		speed = 20
		damage = 1

#	if ready_to_attack and mode == READY:
#		mode = ATTACK
#		$AnimatedSprite.play("attack")
#		$DashTimer.set_wait_time(dash_time)
#		$DashTimer.start()
#		speed = dash_speed
#		pass

	flip_sprite_h(direction)
	
	var collision = move_and_collide(direction * speed * delta)
	
	if collision:
		if mode == MODE.SEEK:
			start_to_seek()
			var rand_degree = get_rand_range(0, 360)
			direction = get_vector_from_radian(rand_degree)
		if collision.collider.is_in_group("Player") and mode == MODE.ATTACK:
			collision.collider.get_hit(damage)
			pass
	
	pass
	

func start_to_seek():
	var rand_degree = get_rand_range(0, 360)
	direction = get_vector_from_radian(rand_degree)
	var seek_change_time = get_rand_range(seek_change_min, seek_change_max)
	$SeekChangeTimer.set_wait_time(seek_change_time)
	$SeekChangeTimer.start()
	pass


func flip_sprite_h(velocity):
	var should_flip = true
	
	if mode == MODE.HURT:
		should_flip = !should_flip
	
	
	if velocity.x < 0:
		$AnimatedSprite.flip_h = should_flip
	if velocity.x > 0:
		$AnimatedSprite.flip_h = !should_flip
	pass


func hurt_for_time(time):
	$HurtTween.interpolate_callback(self, time, "_on_HurtTween_end")
	$HurtTween.start()
	mode = MODE.HURT
	is_shield_on = true
	direction = knockback_direction
	speed = knockback_speed
	if health <= 0:
		speed = knockback_speed * 2
#	$AnimatedSprite.flip_h = !($AnimatedSprite.flip_h)
	
func _on_HurtTween_end():
	if health <= 0:
		mode = MODE.HURT
	else:
		mode = MODE.SEEK
	is_shield_on = false
#	$AnimatedSprite.flip_h = !($AnimatedSprite.flip_h)
	pass


func _on_ReadyTimer_timeout():
	ready_to_attack = true
	$DashTimer.set_wait_time(dash_time)
	$DashTimer.start()
	
	pass


#func _on_ReadyTimer_timeout():
#	print("fin")
#	ready_to_attack = true
#	mode = ATTACK
#	direction = target_direction
#	pass # replace with function body

func _on_DashTimer_timeout():
	ready_to_attack = false
	mode = MODE.SEEK
	start_to_seek()
	damage = 0
	pass # replace with function body


func _on_SeekChangeTimer_timeout():
	start_to_seek()
	pass # replace with function body

