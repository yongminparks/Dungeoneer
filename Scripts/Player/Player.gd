extends KinematicBody2D

#var speed = 120 # default
export var speed = 120

var velocity = Vector2()

#const kick_projectile_scene = preload("res://Scenes/Player/Attack/KickProjectile.tscn")
const playerball_scene = preload("res://Scenes/Player/Attack/PlayerBall.tscn")
const ballHitSprite_scene = preload("res://Scenes/Player/Effect/BallHitSprite.tscn")
const playerDeathParticle_scene = preload("res://Scenes/Particles/PlayerDeathParticle.tscn")

# nodes
onready var camera = get_node("Camera2D")
onready var game = get_node("../../../")

var is_kicking = false

var is_holding_ball = true

var kick_wait_time = 0.4

var max_health = 4
var health = max_health

var is_shield_on = false

var is_getting_hurt = false

var hurt_time = 2
var death_hurt_time = hurt_time + 1

var num_keys = 0

# camera imput for test
func _input(event):
	var zoom_amount = 0.3
	
	# camera zoom
	if Input.is_key_pressed(KEY_1):
		$Camera2D.current = true
		$Camera2D.zoom = $Camera2D.zoom + Vector2(zoom_amount, zoom_amount)
	if Input.is_key_pressed(KEY_2):
		$Camera2D.zoom = $Camera2D.zoom - Vector2(zoom_amount, zoom_amount)


func _ready():
	$Camera2D.current = true
	self.add_to_group("Player")
	if game.current_floor >= 1:
		health = game.player_health
	pass


func _process(delta):
	get_input_movement()
	move_and_slide(velocity)
	state_animation()
	action_process()
	update_aimDirection()
	pass

	
func get_input_movement():
	velocity = Vector2()
	
	if Input.is_action_pressed('ui_right'):
		velocity.x += 1
	if Input.is_action_pressed('ui_left'):
		velocity.x -= 1
	if Input.is_action_pressed('ui_down'):
		velocity.y += 1
	if Input.is_action_pressed('ui_up'):
		velocity.y -= 1
	
	velocity = velocity.normalized() * speed

func is_direction_pressed():
	if Input.is_action_pressed('ui_left') or Input.is_action_pressed('ui_right') or Input.is_action_pressed('ui_up') or Input.is_action_pressed('ui_down'):
		return true
	else:
		return false
	pass


func state_animation():
	
	if is_kicking:
		$AnimatedSprite.play("kick")
	else:
		if velocity.x != 0 or velocity.y != 0:
			$AnimatedSprite.play("run")
			$HoldingBallSprite.play("dribble")
		else:
			$AnimatedSprite.play("idle")
			$HoldingBallSprite.stop()
		
		print($BallAnimationPlayer.current_animation)
	
	if velocity.x < 0:
		$AnimatedSprite.flip_h = true
		$HoldingBallSprite.scale.x = -1
		
	if velocity.x > 0:
		$AnimatedSprite.flip_h = false
		$HoldingBallSprite.scale.x = 1
	
	if is_holding_ball:
		$HoldingBallSprite.visible = true
	else:
		$HoldingBallSprite.visible = false
	pass

func action_process():
	
	if Input.is_action_just_released("ui_x"):
		if is_holding_ball and not is_aim_overlaps_wall():
			shoot_holding_ball()
		elif not is_holding_ball and $KickTimer.is_stopped():
			kick()
	
	if Input.is_action_just_released("ui_accept"):
		is_aim_overlaps_wall()
	pass

func update_aimDirection():
	var aim_direction = velocity.normalized()
	
	if aim_direction == Vector2(0, 0):
		$KickPivot/AimArrowSprite.set_visible(false)
		pass
	else:
		$KickPivot/AimArrowSprite.set_visible(true)
		$KickPivot.global_rotation = aim_direction.angle()


func update_kickDirection():
	var kick_direction = velocity.normalized();
	
	$KickPivot.global_rotation = kick_direction.angle()
	pass


func kick():
	$KickTimer.wait_time = kick_wait_time
	$KickTimer.start()
	pass


func shoot_holding_ball():
	var shoot_ball = playerball_scene.instance()
	get_parent().add_child(shoot_ball)
	shoot_ball.global_position = $KickPivot/KickSpot.global_position
	shoot_ball.direction = ($KickPivot/AimArrowSprite.global_position - self.global_position).normalized()
	shoot_ball.speed = shoot_ball.full_speed
	is_holding_ball = false
	camera.shake(0.2, 10, 8)
	
	#hit animation
	var ballHit_sprite = ballHitSprite_scene.instance()
	get_parent().get_parent().add_child(ballHit_sprite)
	ballHit_sprite.set_transform($KickPivot/HitEffectPosition.global_transform)

	pass

func is_aim_overlaps_wall():
	var wallCheckArea = $KickPivot/KickSpot/WallCheckArea
	var aimOverlaps = wallCheckArea.get_overlapping_bodies()
	
	for body in aimOverlaps:
		if not body.is_in_group("Enemy") and not body.is_in_group("Player"):
			print("aimwall")
			return true

	return false


#func _on_Hitbox_body_entered(body):
#	if body.is_in_group("Ball"):
#		print("get ball")
#		body.velocity = Vector2(0, 0)
#		body.speed = 0
#		body.direction = Vector2(0, 0)
#		body.queue_free()
#		is_holding_ball = true
#	pass # replace with function body


func _on_Hitbox_area_entered(area):
	if area.is_in_group("Ball"):
		var ball = area.get_parent()
		ball.queue_free()
		is_holding_ball = true
	pass # replace with function body


func _on_KickTimer_timeout():
	$KickTimer.stop()
	pass # replace with function body
	
	
func get_hit(damage):
	if not is_shield_on:
		take_damage(damage)
	pass


func take_damage(damage):
	health -= damage
	camera.shake(0.2, 10, 8)
	check_health_to_die()
	pass


func check_health_to_die():
	if health <= 0:
#		player.pause_game_for_time(death_pausetime)
		is_shield_on = true
		self.set_visible(false)
		$CollisionShape2D.disabled = true
		
		self.set_process(false)
		
		var playerDeathParticle = playerDeathParticle_scene.instance()
		playerDeathParticle.position = self.global_position
		get_parent().add_child(playerDeathParticle)
		
		player_dies()
	else:
		hurt_for_time(hurt_time)
	pass
	
func hurt_for_time(time):
	$HurtTween.interpolate_callback(self, time, "_on_HurtTween_end")
	$HurtTween.start()
	$HurtAnimation.play("hurt")
	is_getting_hurt = true
	is_shield_on = true

	if health <= 0:
		pass
	pass

func _on_HurtTween_end():
	is_getting_hurt = false
	is_shield_on = false
	$HurtAnimation.stop(true)
	pass

func player_dies():
	var deathWaitTimer = Timer.new()
	deathWaitTimer.connect("timeout", self, "_on_deathWaitTimer_timeout")
	deathWaitTimer.set_wait_time(2)
	add_child(deathWaitTimer)
	deathWaitTimer.start()
	pass

func _on_deathWaitTimer_timeout():
	$Camera2D/GameOverMenu.show_game_over()
	pass

func show_nextFloorScreen():
	$Camera2D/NextFloorScreen/Cover.visible = true
	var next_floor_text = "- DUNGEON %sF -" % [game.current_floor + 1]
	$Camera2D/NextFloorScreen/Cover/NextFloorLabel.text = next_floor_text
	
	var nextFloorTimer = Timer.new()
	nextFloorTimer.connect("timeout", self, "_on_nextFloorTimer_timeout") 
	nextFloorTimer.set_wait_time(0.5)
	add_child(nextFloorTimer)
	nextFloorTimer.start()
	pass

func _on_nextFloorTimer_timeout():
	print("next floor")
	proceed_to_next_floor()

func proceed_to_next_floor():
	game.proceed_to_next_floor()
	pass
	
func obtain_a_key():
	num_keys += 1
	# show KeyUI Icon
	$Camera2D/UI/UpperLeftContainer/KeyIcon.visible = true
	pass

func consume_a_key():
	num_keys -= 1
	$Camera2D/UI/UpperLeftContainer/KeyIcon.visible = false