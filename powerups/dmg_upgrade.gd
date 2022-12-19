extends AnimatedSprite

export var dmg = 2

func _on_Area2D_area_entered(powerupEater):
	powerupEater.get_parent().raiseDamage(dmg)
	powerupEater.get_parent().get_node("VFX").stop()
	powerupEater.get_parent().get_node("VFX").play("damageUpgrade")
	queue_free()
