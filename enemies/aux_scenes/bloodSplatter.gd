extends Particles2D

func init(x_p, y_p, toRight, onDeath):
	position.x = x_p
	position.y = y_p
	process_material.direction.x = 1 if toRight else -1
	if onDeath:
		process_material.scale = 20
		process_material.initial_velocity *= 1.6
		process_material.gravity.y *= 2
	restart()
	#process_material.scale = 1
	
	return self


func _on_queue_free_delay_timeout():
	queue_free()
