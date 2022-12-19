extends AnimatedSprite

export var hp = 6

func _on_Area2D_area_entered(powerupEater):
	powerupEater.get_parent().heal(-hp)
	powerupEater.get_parent().get_node("VFX").stop()
	powerupEater.get_parent().get_node("VFX").play("healthUpgrade")
	queue_free()
