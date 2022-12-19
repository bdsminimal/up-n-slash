extends Node2D

var parts = []
var vel = 600
var angvel = 16
var velvec_randRotated_inDeg = 26
var angvel_randRange = 4

func init(x_p, y_p, toRight, isFacingRight, prev_velvec):
	parts.append($body)
	parts.append($leg)
	parts.append($leg2)
	parts.append($arm)
	parts.append($head)
	if isFacingRight: $head/Sprite.flip_h = true
	
	position.x = x_p
	position.y = y_p
	prev_velvec.y = 0
	
	for part in parts:
		var cur_velvec = Vector2(0, -vel)
		cur_velvec = cur_velvec.rotated(deg2rad(randf() * velvec_randRotated_inDeg + 10))
		#if !isFacingRight and part.get_node("txtr") is Sprite: part.get_node("txtr").flip_h = true
		#part.get_node("Sprite").flip_h = isFacingRight
		if !toRight: cur_velvec.x = -cur_velvec.x
		part.apply_central_impulse(cur_velvec)
		part.angular_velocity = (angvel if toRight else -angvel) + rand_range(-angvel_randRange, angvel_randRange)
	
	return self


func _on_queue_free_delay_timeout():
	queue_free()


func _on_wait_before_fading_out_timeout():
	$fadeOut.play("fadeOut")
	$queue_free_delay.start()
