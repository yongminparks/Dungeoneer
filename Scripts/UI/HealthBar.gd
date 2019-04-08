extends TextureProgress

onready var player = get_node("../../../../")

func _ready():
	update_healthBar(player.health, player.max_health)
	pass
	
func _process(delta):
	update_healthBar(player.health, player.max_health)

func update_healthBar(health, max_health):
	self.value = health
	self.max_value = max_health
	
	var health_text = "%s/%s" % [health, max_health]
	$HealthText.text = health_text
	pass