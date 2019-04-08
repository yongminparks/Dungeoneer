extends KinematicBody2D

var max_health = 2
var health = max_health

var death_pausetime = 0.1
var damage = 1
var is_shield_on = false

var hurt_time = 0.3
var knockback_direction = Vector2()
var death_hurt_time = 0.7


func _ready():
	add_to_group("Enemy")
	pass

func _process(delta):

	pass


func get_hit(damage):
	if not is_shield_on:
		take_damage(damage)
	pass


func hurt_for_time(time):
	pass


func take_damage(damage):
	health -= damage
	check_health_to_die()
	pass


func check_health_to_die():
	if health <= 0:
#		player.pause_game_for_time(death_pausetime)
		if get_node("AnimatedSprite"):
			get_node("AnimatedSprite").play("hurt")
		is_shield_on = true
		hurt_for_time(death_hurt_time)
		var death_tween = Tween.new()
		add_child(death_tween)
		death_tween.interpolate_callback(self, death_hurt_time, "_on_DeathTween_end")
		death_tween.start()
	else:
		hurt_for_time(hurt_time)
	pass
	
func _on_DeathTween_end():
	queue_free()
	pass


