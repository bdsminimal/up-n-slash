extends CanvasLayer

signal loaded

func _ready():
	$loadingScreen.show()
	$VFX.play("load_progressbar")

func change_healthbar(newHealth, newMaxHealth):
	$hb_sprite/healthbar.max_value = newMaxHealth
	$hb_sprite/healthbar.value = newHealth
	$hb_sprite/hp_digital.text = newHealth as String


func _on_minLoadingTime_timeout():
	emit_signal("loaded")
	$loadingScreen.hide()
