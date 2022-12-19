extends Area2D

func _on_killTrigger_body_entered(body):
	if body.has_method("takeDamage"):
		body.takeDamage(body.maxHealth, body.isFacingRight)
