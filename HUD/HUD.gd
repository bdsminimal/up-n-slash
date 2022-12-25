extends CanvasLayer

signal loaded

func _ready():
	$loadingScreen.show()
	$VFX.play("load_progressbar")

func change_healthbar(newHealth, newMaxHealth, type): #type: 0 - max health changed, 1 - heal, 2 - damage (-1 - dont flicker
	$hb_sprite/bg_npr.rect_size = Vector2(30 + newMaxHealth * 70, 150)
	$hb_sprite/progress.region_rect.size = Vector2(70 * newHealth, 110)
	$hb_sprite/hp_digital.text = newHealth as String
	
	#visuals
	if type == -1: return
	$hb_sprite.self_modulate = Color(1,1,1,1)
	$hb_sprite/progress.modulate = Color(1,1,1,1)
	$hb_sprite/bg_npr.rect_rotation = 0
	if type == 0: $hb_sprite/VFX.play("healthbar_flickerOnUpgrade")
	elif type == 1: $hb_sprite/VFX.play("healthbar_flickerOnHeal")
	elif type == 2: $hb_sprite/VFX.play("healthbar_flickerOnDamage")


func _on_minLoadingTime_timeout():
	emit_signal("loaded")
	$loadingScreen.hide()
	$pauseMenu.set_process(true)
