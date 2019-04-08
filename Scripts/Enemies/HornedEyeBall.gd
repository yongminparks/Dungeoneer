extends "Enemy.gd"

const longBullet_scene = preload("res://Scenes/Enemies/Attacks/LongBullet.tscn")

const MAX_SPEED = 100
const MAX_FORCE = 0.01

var velocity = Vector2()
onready var targetNode = get_node("../Player")
enum STATE {SEEK, FLEE, HURT}
var mode = STATE.SEEK

var detection_distance = 300
var stopping_distance = 100 # shooting_distance
var retreat_distance = 70

var bullet_waittime = 2

var knockback_speed = 50

var speed

func _ready():
	max_health = 4
	health = max_health
	
	self.add_to_group("Enemy")
	pass

func _process(delta):
	var target_distance = position.distance_to(targetNode.position)
	pass
	
	if mode == STATE.HURT:
		$AnimatedSprite.play("hurt")
		move_and_slide(knockback_speed * knockback_direction)
	else:
		$AnimatedSprite.play("default")
		if target_distance > stopping_distance and target_distance < detection_distance:
			mode = STATE.SEEK
			velocity = steer(targetNode.global_position)
			move_and_slide(velocity)
#			$AnimatedSprite.look_at(player.position)
			
		elif target_distance < stopping_distance and target_distance > retreat_distance:
			shoot_bullet()
			pass
		elif target_distance < retreat_distance:
			mode = STATE.FLEE
			velocity = steer(targetNode.global_position)
			move_and_slide(velocity)
	


func steer(target):
	var desired_velocity = (target - self.global_position).normalized() * MAX_SPEED
	
	if mode == STATE.SEEK:
		pass
	elif mode == STATE.FLEE:
		desired_velocity = -desired_velocity * 2
	
	var steer = desired_velocity - velocity
	var target_velocity = velocity + (steer * MAX_FORCE)
	
	flip_sprite_h(target_velocity)
	
	return target_velocity


func flip_sprite_h(velocity):
	if velocity.x < 0:
		$AnimatedSprite.scale.x = -1
	else:
		$AnimatedSprite.scale.x = 1
	pass


func hurt_for_time(time):
	$HurtTween.interpolate_callback(self, time, "_on_HurtTween_end")
	$HurtTween.start()
	mode = STATE.HURT
	is_shield_on = true
	if health <= 0:
		speed = knockback_speed * 2
	pass
	
func _on_HurtTween_end():
	if health <= 0:
		mode = STATE.HURT
	else:
		mode = STATE.SEEK
	is_shield_on = false
#	$AnimatedSprite.flip_h = !($AnimatedSprite.flip_h)
	pass


func shoot_bullet():
	if $BulletTimer.is_stopped():
		
		var bullet = longBullet_scene.instance()
		bullet.set_position($FirePosition.get_global_position())
		get_parent().add_child(bullet)
		bullet.look_at(targetNode.get_global_position())
		bullet.direction = (targetNode.get_global_position() - $FirePosition.get_global_position()).normalized()
		
		$BulletTimer.set_wait_time(bullet_waittime)
		$BulletTimer.start()
		
		$AnimatedSprite/MuzzleFlashSprite.frame = 0
		$AnimatedSprite/MuzzleFlashSprite.play()
		$AnimatedSprite/MuzzleFlashSprite.rotation = bullet.rotation
		
		
	pass


func _on_BulletTimer_timeout():
	$BulletTimer.stop()
	pass # replace with function body
