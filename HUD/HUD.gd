extends CanvasLayer

signal loaded

func _ready():
	$loadingScreen.show()
	$VFX.play("load_progressbar")

func change_healthbar(newHealth, newMaxHealth):
	$healthbar.max_value = newMaxHealth
	$healthbar.value = newHealth
	$hp_digital.text = newHealth as String


func _on_minLoadingTime_timeout():
	emit_signal("loaded")
	$loadingScreen.hide()
